import Foundation
import SwiftData
import ImageIO
import UniformTypeIdentifiers

// One instance per store, composed by the app. Its actor serializes duplicate checks and publication.
actor LocalPlantRepository: PlantRepository {
    private let root: URL
    private var container: ModelContainer?
    private var context: ModelContext?
    // Internal fault seam: tests can fail after mutation/publication, before metadata commit.
    private let beforeCommit: @Sendable () throws -> Void

    init(root: URL, beforeCommit: @escaping @Sendable () throws -> Void = {}) {
        self.root = root
        self.beforeCommit = beforeCommit
    }

    private var photos: URL { root.appendingPathComponent("Photos", isDirectory: true) }

    private func store() throws -> ModelContext {
        if let context { return context }
        do {
            try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
            let configuration = ModelConfiguration(url: root.appendingPathComponent("Plants.store"))
            let container = try ModelContainer(for: PersistedPlant.self, configurations: configuration)
            let context = ModelContext(container)
            context.autosaveEnabled = false
            // Fetch must succeed before cleanup: unreadable metadata must never erase referenced photos.
            let records = try context.fetch(FetchDescriptor<PersistedPlant>())
            let references = Set(try records.map { record in
                _ = try record.domain()
                return record.photoReference
            })
            for file in try FileManager.default.contentsOfDirectory(at: photos, includingPropertiesForKeys: nil) {
                if file.pathExtension == "pending" || (file.pathExtension == "jpg" && !references.contains(file.lastPathComponent)) {
                    try FileManager.default.removeItem(at: file)
                }
            }
            self.container = container
            self.context = context
            return context
        } catch { throw PlantStorageError.storage }
    }

    func loadPlants() async throws -> [Plant] {
        do {
            return try store().fetch(FetchDescriptor<PersistedPlant>()).map { try $0.domain() }
                .sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
        } catch { throw PlantStorageError.storage }
    }

    func savePlant(_ plant: Plant, initialPhoto: Data) async throws {
        try SavePlant.validate(plant)
        guard !initialPhoto.isEmpty else { throw PlantStorageError.validation }
        let context = try store()
        let records: [PersistedPlant]
        do { records = try context.fetch(FetchDescriptor<PersistedPlant>()) }
        catch { throw PlantStorageError.storage }
        guard !records.contains(where: { $0.id == plant.id }) else { throw PlantStorageError.duplicateID }
        guard Self.validJPEG(initialPhoto) else { throw PlantStorageError.photoCorrupt }
        let destination = photos.appendingPathComponent(plant.id.uuidString + ".jpg")
        let temporary = photos.appendingPathComponent(UUID().uuidString + ".pending")
        var published = false
        do {
            try initialPhoto.write(to: temporary, options: .atomic)
            guard Self.validJPEG(try Data(contentsOf: temporary)) else { throw PlantStorageError.photoCorrupt }
            // moveItem refuses to overwrite an existing destination.
            try FileManager.default.moveItem(at: temporary, to: destination)
            published = true
            context.insert(PersistedPlant(plant))
            try beforeCommit()
            try context.save()
        } catch {
            context.rollback()
            try? FileManager.default.removeItem(at: temporary)
            if published { try? FileManager.default.removeItem(at: destination) }
            throw PlantStorageError.storage
        }
    }

    func updatePlant(id: UUID, name: String, location: String?) async throws -> Plant {
        let fields = try UpdatePlant.normalized(name: name, location: location)
        let context = try store()
        do {
            guard let record = try context.fetch(FetchDescriptor<PersistedPlant>()).first(where: { $0.id == id }) else {
                throw PlantStorageError.notFound
            }
            _ = try record.domain()
            record.name = fields.name
            record.location = fields.location
            try beforeCommit()
            try context.save()
            return try record.domain()
        } catch {
            context.rollback()
            if let error = error as? PlantStorageError, error == .notFound { throw error }
            throw PlantStorageError.storage
        }
    }

    func loadInitialPhoto(for id: UUID) async throws -> Data {
        let context = try store()
        do {
            guard let record = try context.fetch(FetchDescriptor<PersistedPlant>()).first(where: { $0.id == id }) else {
                throw PlantStorageError.photoMissing
            }
            _ = try record.domain()
            let url = photos.appendingPathComponent(record.photoReference)
            guard FileManager.default.fileExists(atPath: url.path) else { throw PlantStorageError.photoMissing }
            let data = try Data(contentsOf: url)
            guard Self.validJPEG(data) else { throw PlantStorageError.photoCorrupt }
            return data
        } catch let error as PlantStorageError { throw error }
        catch { throw PlantStorageError.storage }
    }

    private static func validJPEG(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source), type as String == UTType.jpeg.identifier,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { return false }
        return true
    }
}
