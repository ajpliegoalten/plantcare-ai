import XCTest
@testable import PlantCareAI

actor DetailRepository: PlantRepository {
    let plants: [Plant]
    var failure: PlantStorageError?
    var metadataRequests = 0
    var photoRequests: [UUID] = []
    var saves = 0
    private var metadata: [CheckedContinuation<[Plant], Error>] = []
    private var photos: [CheckedContinuation<Data, Error>] = []
    private var waiters: [(Bool, Int, CheckedContinuation<Void, Never>)] = []
    let suspendMetadata: Bool

    init(plants: [Plant] = (1...2).map(StorageTestFixture.plant), failure: PlantStorageError? = nil, suspendMetadata: Bool = false) {
        self.plants = plants
        self.failure = failure
        self.suspendMetadata = suspendMetadata
    }

    func loadPlants() async throws -> [Plant] {
        metadataRequests += 1
        if suspendMetadata {
            return try await withCheckedThrowingContinuation {
                metadata.append($0)
                notify()
            }
        }
        if let failure { throw failure }
        return plants
    }

    func savePlant(_ plant: Plant, initialPhoto: Data) async throws { saves += 1 }
    func loadInitialPhoto(for id: UUID) async throws -> Data {
        try await withCheckedThrowingContinuation {
            photoRequests.append(id)
            photos.append($0)
            notify()
        }
    }
    func counts() -> (Int, [UUID], Int) { (metadataRequests, photoRequests, saves) }
    func wait(metadata: Bool = false, count: Int) async {
        if (metadata ? self.metadata.count : photos.count) >= count { return }
        await withCheckedContinuation { waiters.append((metadata, count, $0)) }
    }
    private func notify() {
        let ready = waiters.filter { ($0.0 ? metadata.count : photos.count) >= $0.1 }
        waiters.removeAll { ($0.0 ? metadata.count : photos.count) >= $0.1 }
        ready.forEach { $0.2.resume() }
    }
    func resolveMetadata(_ index: Int, _ result: Result<[Plant], Error>) { metadata[index].resume(with: result) }
    func resolvePhoto(_ index: Int, _ result: Result<Data, Error>) { photos[index].resume(with: result) }
}

final class LoadPlantDetailTests: XCTestCase {
    func testUUIDLookupDoesNotReadPhotosOrWrite() async throws {
        let plants = (1...2).map(StorageTestFixture.plant)
        let repository = DetailRepository(plants: plants.reversed())
        let load = LoadPlantDetail(repository: repository)
        for plant in plants {
            let actual = try await load.execute(for: plant.id)
            XCTAssertEqual(actual, plant)
        }
        let missing = try await load.execute(for: UUID())
        XCTAssertNil(missing)
        let counts = await repository.counts()
        XCTAssertEqual(counts.0, 3)
        XCTAssertTrue(counts.1.isEmpty)
        XCTAssertEqual(counts.2, 0)
    }

    func testReadFailurePropagatesInsteadOfNotFound() async {
        let repository = DetailRepository(failure: .storage)
        do { _ = try await LoadPlantDetail(repository: repository).execute(for: UUID()); XCTFail("Failure hidden") }
        catch { XCTAssertEqual(error as? PlantStorageError, .storage) }
        let counts = await repository.counts()
        XCTAssertTrue(counts.1.isEmpty)
    }

    func testRealReopenedRepositoryReturnsCompleteMetadataWithoutPhoto() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        for index in 1...2 {
            try await repository!.savePlant(StorageTestFixture.plant(index), initialPhoto: StorageTestFixture.photo(index))
        }
        repository = nil
        try FileManager.default.removeItem(at: root.appendingPathComponent("Photos/\(StorageTestFixture.plant(1).id).jpg"))
        let load = LoadPlantDetail(repository: LocalPlantRepository(root: root))
        for index in 1...2 {
            let actual = try await load.execute(for: StorageTestFixture.plant(index).id)
            XCTAssertEqual(actual, StorageTestFixture.plant(index))
        }
    }
}
