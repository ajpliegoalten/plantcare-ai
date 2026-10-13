import Foundation
import SwiftData
import ImageIO
import UniformTypeIdentifiers

// One instance per store, composed by the app. Its actor serializes duplicate checks and publication.
actor LocalPlantRepository: PlantRepository, CareEventRepository, PlantPhotoRepository, CareEventDeletingRepository, PlantPhotoDeletingRepository {
    private let root: URL
    private var container: ModelContainer?
    private var context: ModelContext?
    // Internal fault seam: tests can fail after mutation/publication, before metadata commit.
    private let beforeCommit: @Sendable () throws -> Void
    private let now: @Sendable () -> Date
    private let beforeCareCommit: @Sendable (CareEvent) throws -> Void
    private let photoPublication: @Sendable (PlantPhoto, Bool) throws -> Void
    private let beforePhotoCommit: @Sendable (PlantPhoto) throws -> Void
    private let beforeDeletionCommit: @Sendable () throws -> Void
    private let beforeDeletionCleanup: @Sendable () throws -> Void

    init(root: URL, beforeCommit: @escaping @Sendable () throws -> Void = {}, now: @escaping @Sendable () -> Date = { Date() }, beforeCareCommit: @escaping @Sendable (CareEvent) throws -> Void = { _ in }, photoPublication: @escaping @Sendable (PlantPhoto, Bool) throws -> Void = { _, _ in }, beforePhotoCommit: @escaping @Sendable (PlantPhoto) throws -> Void = { _ in }, beforeDeletionCommit: @escaping @Sendable () throws -> Void = {}, beforeDeletionCleanup: @escaping @Sendable () throws -> Void = {}) {
        self.root = root
        self.beforeCommit = beforeCommit
        self.now = now
        self.beforeCareCommit = beforeCareCommit
        self.photoPublication = photoPublication
        self.beforePhotoCommit = beforePhotoCommit
        self.beforeDeletionCommit = beforeDeletionCommit
        self.beforeDeletionCleanup = beforeDeletionCleanup
    }

    private var photos: URL { root.appendingPathComponent("Photos", isDirectory: true) }
    private var additionalPhotos: URL { root.appendingPathComponent("AdditionalPhotos", isDirectory: true) }

    func deleteCareEvent(_ expected: CareEvent) async throws -> CareEvent {
        let context: ModelContext
        do { context = try store() } catch { throw CareEventError.readFailure }
        let record: PersistedCareEvent
        let canonical: CareEvent
        do {
            guard let plant = try context.fetch(FetchDescriptor<PersistedPlant>()).first(where: { $0.id == expected.plantID }) else { throw CareEventError.plantNotFound }
            _ = try plant.domain()
            guard let found = try context.fetch(FetchDescriptor<PersistedCareEvent>()).first(where: { $0.id == expected.id && $0.plantID == expected.plantID }) else { throw CareEventError.notFound }
            record = found; canonical = try record.domain()
            guard canonical == expected else { throw CareEventError.conflict }
        } catch {
            if let typed = error as? CareEventError, [.notFound, .plantNotFound, .conflict].contains(typed) { throw typed }
            throw CareEventError.readFailure
        }
        do {
            context.delete(record)
            try beforeDeletionCommit(); try beforeCommit(); try context.save()
            return canonical
        } catch {
            context.rollback()
            throw (error as? CareEventError) ?? .storage
        }
    }

    func deletePhoto(_ expected: PlantPhoto) async throws -> PlantPhoto {
        let context: ModelContext
        do { context = try store() } catch { throw PlantPhotoError.readFailure }
        let canonical: PlantPhoto
        let reference: String
        let record: PersistedPlantPhoto
        do {
            guard let plant = try context.fetch(FetchDescriptor<PersistedPlant>()).first(where: { $0.id == expected.plantID }) else { throw PlantPhotoError.plantNotFound }
            _ = try plant.domain()
            guard let found = try context.fetch(FetchDescriptor<PersistedPlantPhoto>()).first(where: { $0.id == expected.id && $0.plantID == expected.plantID }) else { throw PlantPhotoError.notFound }
            record = found
            canonical = try record.domain() // Also validates the canonical additional-only reference.
            guard canonical == expected else { throw PlantPhotoError.conflict }
            reference = record.photoReference
        } catch {
            if let typed = error as? PlantPhotoError, [.notFound, .plantNotFound, .conflict].contains(typed) { throw typed }
            throw PlantPhotoError.readFailure
        }
        do {
            context.delete(record)
            try beforeDeletionCommit(); try beforeCommit(); try context.save()
        } catch {
            context.rollback()
            throw (error as? PlantPhotoError) ?? .storage
        }
        // Metadata is already committed. Cleanup cannot turn success into retryable failure.
        // A remaining orphan is recovered only after global metadata validation on reopen.
        do {
            try beforeDeletionCleanup()
            let file = additionalPhotos.appendingPathComponent(reference)
            if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        } catch { /* Best effort; never reinsert metadata or claim rollback. */ }
        return canonical
    }

    private func store() throws -> ModelContext {
        if let context { return context }
        do {
            try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: additionalPhotos, withIntermediateDirectories: true)
            let configuration = ModelConfiguration(url: root.appendingPathComponent("Plants.store"))
            let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self, configurations: configuration)
            let context = ModelContext(container)
            context.autosaveEnabled = false
            // Fetch must succeed before cleanup: unreadable metadata must never erase referenced photos.
            let records = try context.fetch(FetchDescriptor<PersistedPlant>())
            let references = Set(try records.map { record in
                _ = try record.domain()
                return record.photoReference
            })
            // Validate the additive entity too before any orphan cleanup.
            let plantIDs = Set(records.map(\.id))
            for event in try context.fetch(FetchDescriptor<PersistedCareEvent>()) {
                guard plantIDs.contains(try event.domain().plantID) else { throw PlantStorageError.storage }
            }
            let additionalReferences = Set(try context.fetch(FetchDescriptor<PersistedPlantPhoto>()).map { record in
                let photo = try record.domain()
                guard plantIDs.contains(photo.plantID) else { throw PlantPhotoError.storage }
                return record.photoReference
            })
            // Both entity sets are valid before either directory is touched.
            for file in try FileManager.default.contentsOfDirectory(at: additionalPhotos, includingPropertiesForKeys: nil) {
                if file.pathExtension == "pending" || (file.pathExtension == "jpg" && !additionalReferences.contains(file.lastPathComponent)) {
                    try FileManager.default.removeItem(at: file)
                }
            }
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

    func savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto {
        try AddPlantPhoto.validateStructure(photo)
        // Suspension occurs before obtaining a context. Publication through save is synchronous.
        do {
            try await LocalPreparedPlantPhotoValidator().validate(
                IdentificationPhoto(id: photo.id, jpeg: jpeg, width: photo.width, height: photo.height))
        } catch is CancellationError { throw CancellationError() }
        catch { throw PlantPhotoError.photoCorrupt }
        let context: ModelContext
        do { context = try store() } catch { throw PlantPhotoError.storage }
        let destination = additionalPhotos.appendingPathComponent(photo.id.uuidString + ".jpg")
        let temporary = additionalPhotos.appendingPathComponent(UUID().uuidString + ".pending")
        var published = false
        do {
            guard try context.fetch(FetchDescriptor<PersistedPlant>()).contains(where: { $0.id == photo.plantID }) else {
                throw PlantPhotoError.plantNotFound
            }
            if let record = try context.fetch(FetchDescriptor<PersistedPlantPhoto>()).first(where: { $0.id == photo.id }) {
                let confirmed = try record.domain()
                guard confirmed == photo else { throw PlantPhotoError.conflict }
                let existing = try readPhoto(record)
                guard existing == jpeg else { throw PlantPhotoError.conflict }
                return confirmed
            }
            try Task.checkCancellation()
            try AddPlantPhoto.validateInsertion(photo, now: now())
            try photoPublication(photo, false)
            try jpeg.write(to: temporary, options: .atomic)
            guard try Data(contentsOf: temporary) == jpeg else { throw PlantPhotoError.storage }
            try FileManager.default.moveItem(at: temporary, to: destination)
            published = true
            try photoPublication(photo, true)
            context.insert(PersistedPlantPhoto(photo))
            try beforePhotoCommit(photo)
            try beforeCommit()
            try context.save()
            return photo
        } catch {
            context.rollback()
            try? FileManager.default.removeItem(at: temporary)
            if published { try? FileManager.default.removeItem(at: destination) }
            throw (error as? PlantPhotoError) ?? (error is CancellationError ? error : PlantPhotoError.storage)
        }
    }

    func loadPhotos(for plantID: UUID) async throws -> [PlantPhoto] {
        do {
            let context = try store()
            guard try context.fetch(FetchDescriptor<PersistedPlant>()).contains(where: { $0.id == plantID }) else {
                throw PlantPhotoError.plantNotFound
            }
            return try context.fetch(FetchDescriptor<PersistedPlantPhoto>()).filter { $0.plantID == plantID }
                .map { try $0.domain() }.sorted {
                    if $0.occurredAt != $1.occurredAt { return $0.occurredAt > $1.occurredAt }
                    if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                    return $0.id.uuidString < $1.id.uuidString
                }
        } catch { throw (error as? PlantPhotoError) ?? .storage }
    }

    func loadPhoto(id: UUID, for plantID: UUID) async throws -> Data {
        do {
            guard let record = try store().fetch(FetchDescriptor<PersistedPlantPhoto>()).first(where: { $0.id == id && $0.plantID == plantID }) else {
                throw PlantPhotoError.notFound
            }
            return try readPhoto(record)
        } catch { throw (error as? PlantPhotoError) ?? .storage }
    }

    private func readPhoto(_ record: PersistedPlantPhoto) throws -> Data {
        let photo = try record.domain()
        let url = additionalPhotos.appendingPathComponent(record.photoReference)
        guard FileManager.default.fileExists(atPath: url.path) else { throw PlantPhotoError.photoMissing }
        let data = try Data(contentsOf: url)
        guard data.count <= 5 * 1024 * 1024, Self.validJPEG(data), data.prefix(2) == Data([0xff, 0xd8]), data.suffix(2) == Data([0xff, 0xd9]),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              properties[kCGImagePropertyExifDictionary] == nil,
              properties[kCGImagePropertyGPSDictionary] == nil,
              properties[kCGImagePropertyOrientation] == nil,
              properties[kCGImagePropertyPixelWidth] as? Int == photo.width,
              properties[kCGImagePropertyPixelHeight] as? Int == photo.height else { throw PlantPhotoError.photoCorrupt }
        return data
    }

    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent {
        let event = RegisterCareEvent.normalized(event)
        try RegisterCareEvent.validateStructure(event)
        let context: ModelContext
        do { context = try store() } catch { throw CareEventError.storage }
        do {
            guard let plant = try context.fetch(FetchDescriptor<PersistedPlant>()).first(where: { $0.id == event.plantID }) else {
                throw CareEventError.plantNotFound
            }
            _ = try plant.domain()
            if let existing = try context.fetch(FetchDescriptor<PersistedCareEvent>()).first(where: { $0.id == event.id }) {
                let confirmed = try existing.domain()
                guard confirmed == event else { throw CareEventError.conflict }
                return confirmed
            }
            try RegisterCareEvent.validateInsertion(event, now: now())
            context.insert(PersistedCareEvent(event))
            try beforeCareCommit(event)
            try beforeCommit()
            try context.save()
            return event
        } catch {
            context.rollback()
            throw (error as? CareEventError) ?? .storage
        }
    }

    func loadCareEvents(for plantID: UUID) async throws -> [CareEvent] {
        do {
            let context = try store()
            guard let plant = try context.fetch(FetchDescriptor<PersistedPlant>()).first(where: { $0.id == plantID }) else {
                throw CareEventError.plantNotFound
            }
            _ = try plant.domain()
            return try context.fetch(FetchDescriptor<PersistedCareEvent>()).filter { $0.plantID == plantID }
                .map { try $0.domain() }.sorted {
                    if $0.occurredAt != $1.occurredAt { return $0.occurredAt > $1.occurredAt }
                    if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                    return $0.id.uuidString < $1.id.uuidString
                }
        } catch { throw (error as? CareEventError) ?? .storage }
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
