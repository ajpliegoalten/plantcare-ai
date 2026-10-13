#if DEBUG && targetEnvironment(simulator)
import Foundation

// Synthetic provider only; never pretends to persist or read definitive analyses.
final class PlantPhotoAnalysisTestFixture: PlantPhotoAnalysisRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private var snapshots: [(Data, PlantAnalysisContext)] = []
    let mode: String
    init(mode: String) { self.mode = mode }
    var invocations: Int { lock.withLock { count } }
    private func capture(_ jpeg: Data, _ context: PlantAnalysisContext) -> Int {
        lock.withLock { count += 1; snapshots.append((jpeg, context)); return count }
    }
    func analyze(jpeg: Data, context: PlantAnalysisContext) async throws -> PlantPhotoAnalysisContent {
        let call = capture(jpeg, context)
        if mode == "busy" { try await Task.sleep(for: .seconds(12)) }
        if mode == "failOnce", call == 1 { throw PlantPhotoAnalysisError.network }
        let long = mode == "long" ? String(repeating: "Observación prudente de la única foto. ", count: 24) + "FINAL OBSERVACIÓN" : "Observación de la foto seleccionada, sin diagnóstico."
        if mode == "insufficient" { return .init(outcome: .insufficientEvidence, observations: ["La foto no permite orientar con seguridad."], possibleCauses: [], checks: []) }
        return .init(outcome: .analysis, observations: [long], possibleCauses: ["Podría influir la luz; no es una certeza."], checks: ["Comprueba el sustrato antes de decidir un cuidado. FINAL COMPROBACIÓN"])
    }
}

struct PlantPhotoAnalysisFixtureVerify: LoadPlantsUseCase {
    let base: any LoadPlantsUseCase
    let repository: LocalPlantRepository
    func execute() async throws -> [Plant] {
        let plants = try await base.execute()
        guard plants.count == 2 else { throw PlantStorageError.storage }
        let a = plants[0].id, b = plants[1].id
        let expectedA = PlantTimelineFixtureLoad.events(for: a)
        let actualA = try await repository.loadCareEvents(for: a)
        guard Set(actualA.map(\.id)) == Set(expectedA.map(\.id)), expectedA.allSatisfy({ actualA.contains($0) }) else { throw PlantStorageError.storage }
        let expectedB = CareEvent(id: PlantTimelineFixtureLoad.id(20), plantID: b, kind: .other,
            occurredAt: Date(timeIntervalSince1970: 172800), note: "SOLO PLANTA B", createdAt: Date(timeIntervalSince1970: 206000), timeZoneIdentifier: "Africa/Abidjan")
        guard try await repository.loadCareEvents(for: b) == [expectedB],
              try await repository.loadPhotos(for: a) == [PlantTimelineFixtureLoad.photo(for: a)],
              try await repository.loadPhotos(for: b).isEmpty else { throw PlantStorageError.storage }
        let expectedJPEG = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2)).jpeg
        guard try await repository.loadPhoto(id: PlantTimelineFixtureLoad.id(10), for: a) == expectedJPEG else { throw PlantStorageError.photoCorrupt }
        return plants
    }
}
#endif
