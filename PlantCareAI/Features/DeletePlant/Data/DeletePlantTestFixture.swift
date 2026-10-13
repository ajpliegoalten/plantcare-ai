#if DEBUG && targetEnvironment(simulator)
import Foundation
import SwiftData

final class DeletePlantTestFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    let mode: String
    init(mode: String) { self.mode = mode }
    func beforeCommit() throws {
        let call = lock.withLock { calls += 1; return calls }
        if mode == "busy" { Thread.sleep(forTimeInterval: 12) }
        if mode == "failAlways" || (mode == "failOnce" && call == 1) { throw PlantDeletionError.storage }
    }
}

struct DeletePlantFixtureLoad: LoadPlantsUseCase {
    let base: any LoadPlantsUseCase
    let repository: LocalPlantRepository
    let root: URL
    let seed: Bool
    let verify: String?

    static func photos(_ plant: Plant, index: Int) -> [PlantPhoto] {
        (0..<2).map { offset in
            PlantPhoto(id: PlantTimelineFixtureLoad.id(100 * index + offset), plantID: plant.id,
                occurredAt: Date(timeIntervalSince1970: 86400), createdAt: Date(timeIntervalSince1970: Double(210000 + offset)),
                timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)
        }
    }
    static func events(_ plant: Plant, index: Int) -> [CareEvent] {
        PlantTimelineFixtureLoad.events(for: plant.id).enumerated().map { offset, value in
            CareEvent(id: PlantTimelineFixtureLoad.id(100 * index + offset), plantID: plant.id, kind: value.kind,
                occurredAt: value.occurredAt, note: value.note, createdAt: value.createdAt, timeZoneIdentifier: value.timeZoneIdentifier)
        }
    }
    static func analyses(_ plant: Plant, index: Int) -> [PlantPhotoAnalysisAcceptance] {
        let additional = photos(plant, index: index)[0]
        let sources: [PlantPhotoDescriptor] = [
            .init(id: .initial(plant.id), date: plant.createdAt, createdAt: plant.createdAt),
            .init(id: .additional(additional.id), date: additional.occurredAt, createdAt: additional.createdAt)
        ]
        return sources.enumerated().map { offset, source in
            .init(record: .init(id: PlantTimelineFixtureLoad.id(100 * index + 10 + offset), plantID: plant.id,
                identity: source.id, photoDate: source.date, queriedAt: Date(timeIntervalSince1970: 300000), revision: 1,
                acceptedAt: Date(timeIntervalSince1970: 300001), content: .init(outcome: .analysis,
                    observations: ["Texto literal del ejemplar \(index)\ne\u{301}"], possibleCauses: ["Posibilidad, no hecho"], checks: ["Comprobar sin inferir"])), source: source)
        }
    }

    func execute() async throws -> [Plant] {
        let plants = try await base.execute()
        let jpeg = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2)).jpeg
        if seed {
            for (offset, plant) in plants.enumerated() {
                for event in Self.events(plant, index: offset + 1) { _ = try await repository.saveCareEvent(event) }
                for photo in Self.photos(plant, index: offset + 1) { _ = try await repository.savePhoto(photo, jpeg: jpeg) }
                for analysis in Self.analyses(plant, index: offset + 1) { _ = try await repository.saveAccepted(analysis) }
            }
        }
        guard let verify else { return plants }
        let expectedIndices = verify == "deleted" ? [2] : verify == "empty" ? [] : [1, 2]
        guard plants == expectedIndices.map(StorageTestFixture.plant) else { throw PlantStorageError.storage }
        for index in expectedIndices {
            let plant = StorageTestFixture.plant(index)
            guard try await repository.loadInitialPhoto(for: plant.id) == StorageTestFixture.photo(index),
                  try await repository.loadCareEvents(for: plant.id).count == 5,
                  try await repository.loadPhotos(for: plant.id).count == 2,
                  Set(try await repository.loadSavedAnalyses(for: plant.id).map(\.id)) == Set(Self.analyses(plant, index: index).map { $0.record.id }) else { throw PlantStorageError.storage }
            let actualPhotos = try await repository.loadPhotos(for: plant.id)
            let actualEvents = try await repository.loadCareEvents(for: plant.id)
            guard Self.events(plant, index: index).allSatisfy(actualEvents.contains) else { throw PlantStorageError.storage }
            guard Self.photos(plant, index: index).allSatisfy(actualPhotos.contains) else { throw PlantStorageError.storage }
            let actualAnalyses = try await repository.loadSavedAnalyses(for: plant.id)
            guard Self.analyses(plant, index: index).allSatisfy({ actualAnalyses.contains($0.record) }) else { throw PlantStorageError.storage }
            for photo in actualPhotos {
                guard try await repository.loadPhoto(id: photo.id, for: plant.id) == jpeg else { throw PlantStorageError.photoCorrupt }
            }
        }
        // Raw entity counts detect invisible orphan children; no old two-plant verifier.
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self, PersistedPlantPhotoAnalysis.self,
            configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        guard try context.fetchCount(FetchDescriptor<PersistedPlant>()) == expectedIndices.count,
              try context.fetchCount(FetchDescriptor<PersistedCareEvent>()) == expectedIndices.count * 5,
              try context.fetchCount(FetchDescriptor<PersistedPlantPhoto>()) == expectedIndices.count * 2,
              try context.fetchCount(FetchDescriptor<PersistedPlantPhotoAnalysis>()) == expectedIndices.count * 2 else { throw PlantStorageError.storage }
        for index in [1, 2] where !expectedIndices.contains(index) {
            let plant = StorageTestFixture.plant(index)
            let files = [root.appendingPathComponent("Photos/\(plant.id).jpg")] + Self.photos(plant, index: index).map { root.appendingPathComponent("AdditionalPhotos/\($0.id).jpg") }
            guard files.allSatisfy({ !FileManager.default.fileExists(atPath: $0.path) }) else { throw PlantStorageError.storage }
        }
        return plants
    }
}
#endif
