import XCTest
@testable import PlantCareAI

@MainActor
final class PlantPhotoPagerViewModelTests: XCTestCase {
    func testDeleteSuspendedSelectedFallbackInitialAndNonselectedPreservesIdentityAndCache() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
        let second = PlantTimelineFixtureLoad.photo(for: fixture.plant.id)
        _ = try await repository.savePhoto(second, jpeg: fixture.jpeg)
        let vm = PlantPhotoPagerViewModel(plant: fixture.plant, loadMetadata: LoadPlantPhotos(repository: repository),
            loadAdditional: LoadPlantPhoto(repository: repository), loadInitial: LoadInitialPlantPhoto(repository: repository))
        vm.appear(); await wait { vm.isComplete }; await wait { vm.initialImage != nil }
        let initial = vm.initialImage
        vm.select(.additional(second.id)); await wait { if case .loaded = vm.imageState { return true }; return false }
        vm.disappear(preservingSelection: true)
        _ = try await repository.deletePhoto(fixture.photo); vm.deleted(fixture.photo)
        XCTAssertEqual(vm.selected, .additional(second.id)); XCTAssertEqual(vm.descriptors.count, 2)
        XCTAssertTrue(vm.initialImage === initial)
        vm.appear(); await wait { vm.isComplete }
        XCTAssertEqual(vm.index, 1); XCTAssertFalse(vm.canNext); XCTAssertTrue(vm.canPrevious)
        vm.disappear(preservingSelection: true)
        _ = try await repository.deletePhoto(second); vm.deleted(second)
        XCTAssertEqual(vm.selected, .initial(fixture.plant.id)); XCTAssertEqual(vm.descriptors.count, 1)
        guard case .idle = vm.imageState(for: .additional(second.id)) else { return XCTFail("Deleted page cached") }
        XCTAssertTrue(vm.initialImage === initial)
        vm.appear(); await wait { vm.isComplete }
        XCTAssertEqual(vm.index, 0); XCTAssertFalse(vm.canNext); XCTAssertFalse(vm.canPrevious); vm.disappear()
    }

    func testDeleteInvalidatesLateMetadataImageAndFailedReconcileIsNotComplete() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let initial = LocalPlantRepository(root: root), plant = StorageTestFixture.plant(1), reads = PhotoReadGate()
        try await initial.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let photo = PlantTimelineFixtureLoad.photo(for: plant.id)
        let vm = PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: reads),
            loadAdditional: LoadPlantPhoto(repository: reads), loadInitial: LoadInitialPlantPhoto(repository: initial))
        vm.appear(); await reads.waitMetadata(1); await reads.metadata(0, .success([photo])); await wait { vm.isComplete }
        vm.select(.additional(photo.id)); await reads.waitImages(1)
        vm.refresh(); await reads.waitMetadata(2); vm.disappear(preservingSelection: true)
        vm.deleted(photo); XCTAssertEqual(vm.selected, .initial(plant.id)); XCTAssertEqual(vm.descriptors.count, 1)
        await reads.metadata(1, .success([photo])); await reads.image(0, .success(StorageTestFixture.photo(2)))
        await Task.yield(); XCTAssertEqual(vm.descriptors.count, 1)
        guard case .idle = vm.imageState(for: .additional(photo.id)) else { return XCTFail("Late image resurrected") }
        vm.appear(); await reads.waitMetadata(3); await reads.metadata(2, .failure(PlantPhotoError.storage))
        await wait { if case .failed = vm.metadataState { return true }; return false }
        XCTAssertFalse(vm.isComplete); XCTAssertEqual(vm.selected, .initial(plant.id)); vm.disappear()
    }
    private func wait(_ condition: () -> Bool) async {
        for _ in 0..<1000 { if condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
    func testRetroactiveCommitSelectedReconcileCacheBoundReadOnlyAndLifecycleInitial() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let commits = PhotoCommitCounter()
        let repository = LocalPlantRepository(root: root, beforeCommit: { commits.record() })
        let plant = StorageTestFixture.plant(1)
        try await repository.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let prepared = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
        var photos: [PlantPhoto] = []
        for day in 1...4 {
            let photo = PlantPhoto(id: UUID(), plantID: plant.id,
                occurredAt: try AddPlantPhoto.startOfDay(year: 1960, month: 1, day: day, zone: try AddPlantPhoto.zone("Europe/Madrid")),
                createdAt: plant.createdAt.addingTimeInterval(Double(day)), timeZoneIdentifier: "Europe/Madrid", width: prepared.width, height: prepared.height)
            photos.append(try await repository.savePhoto(photo, jpeg: prepared.jpeg))
        }
        let committedCount = commits.value
        XCTAssertEqual(committedCount, 5) // One initial plant + four real additional-photo commits.
        let vm = PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: repository),
            loadAdditional: LoadPlantPhoto(repository: repository), loadInitial: LoadInitialPlantPhoto(repository: repository))
        vm.appear(); await wait { vm.isComplete }; await wait { if case .loaded = vm.imageState { return true }; return false }
        XCTAssertEqual(vm.selected, .initial(plant.id)); XCTAssertFalse(vm.canPrevious); XCTAssertTrue(vm.canNext)
        for photo in photos {
            vm.select(.additional(photo.id)); await wait { if case .loaded = vm.imageState { return true }; return false }
            XCTAssertLessThanOrEqual(vm.cachedImageCount, 3)
            XCTAssertNotNil(vm.initialImage)
        }
        vm.committed(photos[3], image: try AddPlantPhotoViewModel.thumbnail(prepared.jpeg))
        XCTAssertEqual(vm.selected, .additional(photos[3].id)); await wait { vm.isComplete }
        XCTAssertEqual(vm.selected, .additional(photos[3].id)); XCTAssertFalse(vm.canNext)
        vm.appear() // Sheet dismissal must not reset the confirmed selection.
        XCTAssertEqual(vm.selected, .additional(photos[3].id))
        vm.disappear(preservingSelection: true)
        XCTAssertEqual(vm.selected, .additional(photos[3].id)); XCTAssertLessThanOrEqual(vm.cachedImageCount, 3)
        XCTAssertNotNil(vm.initialImage)
        vm.appear(); await wait { if case .loaded = vm.imageState { return true }; return false }
        XCTAssertEqual(vm.selected, .additional(photos[3].id))
        vm.select(.additional(photos[2].id)); await wait { if case .loaded = vm.imageState { return true }; return false }
        vm.select(.additional(photos[3].id)); await wait { if case .loaded = vm.imageState { return true }; return false }
        guard case .loaded = vm.imageState(for: .additional(photos[2].id)) else { return XCTFail("Previous page must retain its bounded thumbnail for the slide") }
        let actual = try await repository.loadPhotos(for: plant.id); XCTAssertEqual(Set(actual.map(\.id)), Set(photos.map(\.id)))
        vm.disappear(); XCTAssertEqual(vm.cachedImageCount, 0); XCTAssertEqual(vm.selected, .initial(plant.id))
        vm.appear(); await wait { if case .loaded = vm.imageState { return true }; return false }
        XCTAssertEqual(vm.selected, .initial(plant.id)); vm.disappear()
        XCTAssertEqual(commits.value, committedCount) // Native pager intentions/refresh/lifecycle never dispatch a write.
    }
    func testMetadataErrorNotEmptyAndConfirmedPhotoSurvivesFailedReconcile() async throws {
        let repository = PhotoTestRepository(); await repository.setFail(true)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let initial = LocalPlantRepository(root: root); let plant = StorageTestFixture.plant(1)
        try await initial.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let vm = PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: repository),
            loadAdditional: LoadPlantPhoto(repository: repository), loadInitial: LoadInitialPlantPhoto(repository: initial))
        vm.appear(); await wait { if case .failed = vm.metadataState { return true }; return false }
        XCTAssertFalse(vm.isComplete); XCTAssertFalse(vm.canNext)
        let photo = PlantPhoto(id: UUID(), plantID: plant.id, occurredAt: plant.createdAt.addingTimeInterval(-1),
            createdAt: plant.createdAt, timeZoneIdentifier: "Europe/Madrid", width: 640, height: 480)
        vm.committed(photo, image: try AddPlantPhotoViewModel.thumbnail(StorageTestFixture.photo(2)))
        await wait { if case .failed = vm.metadataState { return true }; return false }
        XCTAssertEqual(vm.selected, .additional(photo.id)); XCTAssertEqual(vm.descriptors.count, 2)
        guard case .loaded = vm.imageState else { return XCTFail() }; vm.disappear()
    }
    func testLateMetadataCannotSuppressCommitAndLateImageCannotPublishToNewIdentity() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let initial = LocalPlantRepository(root: root), plant = StorageTestFixture.plant(1)
        try await initial.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let reads = PhotoReadGate()
        let vm = PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: reads),
            loadAdditional: LoadPlantPhoto(repository: reads), loadInitial: LoadInitialPlantPhoto(repository: initial))
        func photo(_ day: Double) -> PlantPhoto {
            PlantPhoto(id: UUID(), plantID: plant.id, occurredAt: plant.createdAt.addingTimeInterval(day),
                       createdAt: plant.createdAt, timeZoneIdentifier: "Europe/Madrid", width: 640, height: 480)
        }
        let x = photo(-2), y = photo(-1)
        vm.appear(); await reads.waitMetadata(1)
        vm.committed(x, image: try AddPlantPhotoViewModel.thumbnail(StorageTestFixture.photo(1)))
        await reads.waitMetadata(2)
        await reads.metadata(0, .success([])); await Task.yield()
        XCTAssertEqual(vm.selected, .additional(x.id)); XCTAssertEqual(vm.descriptors.count, 2)
        await reads.metadata(1, .success([x, y])); await wait { vm.isComplete }
        // Force X's byte read even though the commit gave it a thumbnail, then leave X.
        vm.retryImage(); await reads.waitImages(1)
        vm.select(.additional(y.id)); await reads.waitImages(2)
        await reads.image(0, .failure(PlantPhotoError.photoMissing)); await Task.yield()
        XCTAssertEqual(vm.selected, .additional(y.id)); guard case .loading = vm.imageState else { return XCTFail() }
        await reads.image(1, .success(StorageTestFixture.photo(2)))
        await wait { if case .loaded = vm.imageState { return true }; return false }
        XCTAssertEqual(vm.selected, .additional(y.id)); XCTAssertEqual(vm.current.date, y.occurredAt)
        vm.retryImage(); await reads.waitImages(3); vm.disappear()
        await reads.image(2, .success(StorageTestFixture.photo(1))); await Task.yield()
        XCTAssertEqual(vm.selected, .initial(plant.id)); guard case .idle = vm.imageState else { return XCTFail() }
        let writes = await reads.writes; XCTAssertEqual(writes, 0)
    }
}

private final class PhotoCommitCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func record() { lock.lock(); defer { lock.unlock() }; count += 1 }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}

private actor PhotoReadGate: PlantPhotoRepository {
    var metadataPending: [CheckedContinuation<[PlantPhoto], Error>] = []
    var imagesPending: [CheckedContinuation<Data, Error>] = []
    var writes = 0
    func savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto { writes += 1; return photo }
    func loadPhotos(for plantID: UUID) async throws -> [PlantPhoto] { try await withCheckedThrowingContinuation { metadataPending.append($0) } }
    func loadPhoto(id: UUID, for plantID: UUID) async throws -> Data { try await withCheckedThrowingContinuation { imagesPending.append($0) } }
    func waitMetadata(_ count: Int) async { while metadataPending.count < count { await Task.yield() } }
    func waitImages(_ count: Int) async { while imagesPending.count < count { await Task.yield() } }
    func metadata(_ index: Int, _ result: Result<[PlantPhoto], Error>) { metadataPending[index].resume(with: result) }
    func image(_ index: Int, _ result: Result<Data, Error>) { imagesPending[index].resume(with: result) }
}
