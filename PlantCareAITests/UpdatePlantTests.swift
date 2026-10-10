import XCTest
@testable import PlantCareAI

actor EditRepository: PlantRepository {
    var plants = (1...2).map(StorageTestFixture.plant)
    var calls: [(UUID, String, String?)] = []
    var error: PlantStorageError?
    let suspended: Bool
    private var pending: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?
    init(suspended: Bool = false) { self.suspended = suspended }
    func loadPlants() async throws -> [Plant] { plants }
    func savePlant(_ plant: Plant, initialPhoto: Data) async throws { XCTFail("Update must not create") }
    func loadInitialPhoto(for id: UUID) async throws -> Data { throw PlantStorageError.photoMissing }
    func setError(_ error: PlantStorageError?) { self.error = error }
    func count() -> Int { calls.count }
    func inputs() -> [(UUID, String, String?)] { calls }
    func wait() async {
        if pending != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func release() { pending?.resume(); pending = nil }
    func updatePlant(id: UUID, name: String, location: String?) async throws -> Plant {
        calls.append((id, name, location))
        if suspended {
            await withCheckedContinuation { pending = $0; started?.resume(); started = nil }
        }
        if let error { throw error }
        guard let index = plants.firstIndex(where: { $0.id == id }) else { throw PlantStorageError.notFound }
        let p = plants[index]
        let updated = Plant(id: id, name: name, confirmedSpecies: p.confirmedSpecies, createdAt: p.createdAt, location: location, careSheet: p.careSheet)
        plants[index] = updated
        return updated
    }
}

final class UpdatePlantTests: XCTestCase {
    func testNormalizationAndIsolationAndErrors() async throws {
        let repository = EditRepository()
        let useCase = UpdatePlant(repository: repository)
        let a = StorageTestFixture.plant(1), b = StorageTestFixture.plant(2)
        let result = try await useCase.execute(id: a.id, name: " \nMi  monstéra 🌿\n", location: " \n ")
        XCTAssertEqual(result.name, "Mi  monstéra 🌿")
        XCTAssertNil(result.location)
        let inputs = await repository.inputs()
        XCTAssertEqual(inputs[0].0, a.id)
        XCTAssertEqual(inputs[0].1, result.name)
        XCTAssertNil(inputs[0].2)
        let plants = try await repository.loadPlants()
        XCTAssertEqual(plants[1], b)
        for name in ["", " \n\t"] {
            do { _ = try await useCase.execute(id: a.id, name: name, location: "Sala"); XCTFail("Invalid accepted") }
            catch { XCTAssertEqual(error as? PlantStorageError, .validation) }
        }
        let count = await repository.count(); XCTAssertEqual(count, 1)
        await repository.setError(.storage)
        do { _ = try await useCase.execute(id: a.id, name: "A", location: nil); XCTFail("Error hidden") }
        catch { XCTAssertEqual(error as? PlantStorageError, .storage) }
    }
}
