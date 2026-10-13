#if DEBUG && targetEnvironment(simulator)
import Foundation

// Opt-in UUID-scoped real-store seed. No sidecar or fabricated history on read.
struct PlantTimelineFixtureLoad: LoadPlantsUseCase {
    let base: any LoadPlantsUseCase
    let repository: LocalPlantRepository
    let seed: Bool
    let mode: String

    static func id(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "10000000-0000-0000-0000-%012d", value))!
    }
    static let longNote = "Nota literal: " + String(repeating: "Conserva este texto completo, sin recomendaciones generadas. ", count: 12) + "FINAL DE LA NOTA"
    static func events(for plantID: UUID) -> [CareEvent] {
        CareEvent.Kind.allCases.enumerated().map { offset, kind in
            CareEvent(id: id(offset + 1), plantID: plantID, kind: kind,
                occurredAt: Date(timeIntervalSince1970: offset == 4 ? -86400 : 86400),
                note: offset == 2 ? longNote : "Nota propia " + kind.rawValue,
                createdAt: Date(timeIntervalSince1970: 200000 + Double(offset) * 1000), timeZoneIdentifier: "Africa/Abidjan")
        }
    }
    static func photo(for plantID: UUID) -> PlantPhoto {
        PlantPhoto(id: id(10), plantID: plantID, occurredAt: Date(timeIntervalSince1970: 86400),
                   createdAt: Date(timeIntervalSince1970: 205000), timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)
    }
    func execute() async throws -> [Plant] {
        let plants = try await base.execute()
        if seed, let plant = plants.first {
            if mode != "photosOnly" && mode != "scrollPhotos" {
                for event in Self.events(for: plant.id) { _ = try await repository.saveCareEvent(event) }
            }
            if mode == "scrollPhotos" {
                let pink = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1))
                let blue = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
                for index in 10...17 {
                    let photo = PlantPhoto(id: Self.id(index), plantID: plant.id,
                        occurredAt: Date(timeIntervalSince1970: 86400), createdAt: Date(timeIntervalSince1970: Double(205000 + index)),
                        timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)
                    _ = try await repository.savePhoto(photo, jpeg: index.isMultiple(of: 2) ? pink.jpeg : blue.jpeg)
                }
            } else {
                let prepared = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
                _ = try await repository.savePhoto(Self.photo(for: plant.id), jpeg: prepared.jpeg)
            }
            // B's event is intentionally distinct, so isolation assertions have a sentinel.
            if mode != "photosOnly", mode != "scrollPhotos", plants.count > 1 {
                _ = try await repository.saveCareEvent(CareEvent(id: Self.id(20), plantID: plants[1].id, kind: .other,
                    occurredAt: Date(timeIntervalSince1970: 172800), note: "SOLO PLANTA B",
                    createdAt: Date(timeIntervalSince1970: 206000), timeZoneIdentifier: "Africa/Abidjan"))
            }
        }
        return plants
    }
}

actor PlantTimelineReadTestFixture: LoadPlantTimelineUseCase {
    let base: any LoadPlantTimelineUseCase
    private var failed = false
    init(base: any LoadPlantTimelineUseCase) { self.base = base }
    func execute(for plantID: UUID) async throws -> [PlantTimelineEntry]? {
        let entries = try await base.execute(for: plantID)
        if !failed { failed = true; throw PlantStorageError.storage }
        return entries
    }
}
// Synchronous pre-save seam, scoped to the same opt-in UUID store. No network or sidecar.
final class HistoryDeletionTestFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var remainingFailures: Int
    private let delay: TimeInterval
    init(mode: String) {
        remainingFailures = mode == "failOnce" ? 1 : (mode == "failAlways" ? Int.max : 0)
        delay = mode == "busy" ? 12 : 0
    }
    func beforeCommit() throws {
        lock.lock(); defer { lock.unlock() }
        if delay > 0 { Thread.sleep(forTimeInterval: delay) }
        if remainingFailures > 0 { remainingFailures -= 1; throw CareEventError.storage }
    }
}
#endif
