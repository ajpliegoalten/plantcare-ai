import XCTest
import UIKit
@testable import PlantCareAI

actor CardPhotoRepository: PlantRepository {
    func updatePlant(id: UUID, name: String, location: String?) async throws -> Plant { throw PlantStorageError.storage }
    private var requests: [(UUID, CheckedContinuation<Data, Error>)] = []
    private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []
    func loadPlants() async throws -> [Plant] { [] }
    func savePlant(_ plant: Plant, initialPhoto: Data) async throws {}
    func loadInitialPhoto(for id: UUID) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            requests.append((id, continuation))
            let ready = waiters.filter { requests.count >= $0.0 }
            waiters.removeAll { requests.count >= $0.0 }
            ready.forEach { $0.1.resume() }
        }
    }
    func waitForRequests(_ count: Int) async {
        if requests.count >= count { return }
        await withCheckedContinuation { waiters.append((count, $0)) }
    }
    func resolve(_ index: Int, _ result: Result<Data, Error>) { requests[index].1.resume(with: result) }
    func ids() -> [UUID] { requests.map { $0.0 } }
}

@MainActor
final class PlantCardViewModelTests: XCTestCase {
    private func card(_ index: Int, _ repository: CardPhotoRepository) -> PlantCardViewModel {
        PlantCardViewModel(plant: StorageTestFixture.plant(index), loadPhoto: LoadInitialPlantPhoto(repository: repository))
    }

    func testDemandLoadingIdentityAndDuplicateRequests() async {
        let repository = CardPhotoRepository()
        let first = card(1, repository), second = card(2, repository)
        let initially = await repository.ids()
        XCTAssertTrue(initially.isEmpty)
        let task = Task { await first.load() }
        await repository.waitForRequests(1)
        await first.load() // Already loading: no second request.
        await repository.resolve(0, .success(StorageTestFixture.photo(1)))
        await task.value
        await first.load() // Cached image.
        let secondTask = Task { await second.load() }
        await repository.waitForRequests(2)
        await repository.resolve(1, .success(StorageTestFixture.photo(2)))
        await secondTask.value
        let ids = await repository.ids()
        XCTAssertEqual(ids, [first.id, second.id])
        guard case .loaded(let image1) = first.photoState,
              case .loaded(let image2) = second.photoState else { return XCTFail("Images not loaded") }
        XCTAssertNotEqual(image1.pngData(), image2.pngData())
        XCTAssertEqual(image1.size.width / image1.size.height, 4 / 3, accuracy: 0.01)
        let plant = first.plant
        let updated = Plant(id: plant.id, name: "Mi monstera", confirmedSpecies: plant.confirmedSpecies, createdAt: plant.createdAt, location: "Salón", careSheet: plant.careSheet)
        first.applyUpdatedPlant(updated)
        first.applyUpdatedPlant(second.plant) // Never replace another UUID.
        await first.load()
        XCTAssertEqual(first.plant, updated)
        guard case .loaded(let retained) = first.photoState else { return XCTFail("Cache lost") }
        XCTAssertTrue(retained === image1)
        let afterEdit = await repository.ids(); XCTAssertEqual(afterEdit, ids)
    }

    func testFailureAndRetryAreIsolated() async {
        let repository = CardPhotoRepository()
        let first = card(1, repository), second = card(2, repository)
        let initial = Task { await first.load() }
        await repository.waitForRequests(1)
        await repository.resolve(0, .failure(PlantStorageError.photoMissing))
        await initial.value
        guard case .failed = first.photoState else { return XCTFail("Expected failed") }
        guard case .idle = second.photoState else { return XCTFail("Other card changed") }
        let retry = Task { await first.retry() }
        await repository.waitForRequests(2)
        await repository.resolve(1, .success(StorageTestFixture.photo(1)))
        await retry.value
        guard case .loaded = first.photoState else { return XCTFail("Retry failed") }
        let ids = await repository.ids()
        XCTAssertEqual(ids, [first.id, first.id])
    }

    func testInvalidDecodeFailsWithoutChangingPlant() async {
        let repository = CardPhotoRepository()
        let model = card(1, repository)
        let task = Task { await model.load() }
        await repository.waitForRequests(1)
        await repository.resolve(0, .success(Data("not an image".utf8)))
        await task.value
        guard case .failed = model.photoState else { return XCTFail("Invalid image accepted") }
        XCTAssertEqual(model.plant, StorageTestFixture.plant(1))
    }

    func testCancelledOldResponseCannotReplaceNewImage() async {
        let repository = CardPhotoRepository()
        let model = card(1, repository)
        let old = Task { await model.load() }
        await repository.waitForRequests(1)
        // Invalidate even if a provider ignores cancellation and finishes later.
        model.cancelLoading()
        let new = Task { await model.load() }
        await repository.waitForRequests(2)
        await repository.resolve(1, .success(StorageTestFixture.photo(1)))
        await new.value
        guard case .loaded(let expected) = model.photoState else { return XCTFail("New image missing") }
        await repository.resolve(0, .success(StorageTestFixture.photo(2)))
        await old.value
        guard case .loaded(let actual) = model.photoState else { return XCTFail("Old response changed state") }
        XCTAssertTrue(actual === expected)
    }

    func testTaskCancellationIsNotVisibleFailure() async {
        let repository = CardPhotoRepository()
        let model = card(1, repository)
        let task = Task { await model.load() }
        await repository.waitForRequests(1)
        task.cancel()
        await repository.resolve(0, .failure(CancellationError()))
        await task.value
        guard case .idle = model.photoState else { return XCTFail("Cancellation shown as failure") }
    }

    func testPresentationImageIsBounded() async {
        let repository = CardPhotoRepository()
        let model = card(1, repository)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let bytes = UIGraphicsImageRenderer(size: CGSize(width: 2400, height: 1800), format: format)
            .image { $0.fill(CGRect(x: 0, y: 0, width: 2400, height: 1800)) }.jpegData(compressionQuality: 0.8)!
        let task = Task { await model.load() }
        await repository.waitForRequests(1)
        await repository.resolve(0, .success(bytes))
        await task.value
        guard case .loaded(let image) = model.photoState else { return XCTFail("Missing image") }
        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 1600)
    }
}
