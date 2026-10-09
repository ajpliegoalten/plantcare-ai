import XCTest
import UIKit
@testable import PlantCareAI

@MainActor
final class PlantDetailViewModelTests: XCTestCase {
    private func model(_ index: Int = 1, _ repository: DetailRepository) -> PlantDetailViewModel {
        PlantDetailViewModel(id: StorageTestFixture.plant(index).id, loadDetail: LoadPlantDetail(repository: repository), loadPhoto: LoadInitialPlantPhoto(repository: repository))
    }
    private func assertPlant(_ model: PlantDetailViewModel, _ index: Int, file: StaticString = #filePath, line: UInt = #line) {
        guard case .loaded(let plant) = model.state else { return XCTFail("Metadata missing", file: file, line: line) }
        XCTAssertEqual(plant, StorageTestFixture.plant(index), file: file, line: line)
    }

    func testMetadataPrecedesPhotoAndTwoInstancesStayIndependentAndCached() async {
        let repository = DetailRepository()
        let first = model(1, repository), second = model(2, repository)
        let one = Task { await first.load() }
        await repository.wait(count: 1)
        assertPlant(first, 1)
        guard case .loading = first.photoState else { return XCTFail("Photo should still be pending") }
        await first.load() // No duplicate IO.
        await repository.resolvePhoto(0, .success(StorageTestFixture.photo(1)))
        await one.value
        await first.load() // Cached metadata/image.
        let two = Task { await second.load() }
        await repository.wait(count: 2)
        assertPlant(second, 2)
        await repository.resolvePhoto(1, .success(StorageTestFixture.photo(2)))
        await two.value
        assertPlant(first, 1)
        let counts = await repository.counts()
        XCTAssertEqual(counts.0, 2)
        XCTAssertEqual(counts.1, [first.id, second.id])
        guard case .loaded(let image1) = first.photoState, case .loaded(let image2) = second.photoState else { return XCTFail("Images missing") }
        XCTAssertNotEqual(image1.pngData(), image2.pngData())
    }

    func testMissingCorruptInvalidDecodeAndRealRetryDoNotReloadMetadata() async {
        for result: Result<Data, Error> in [.failure(PlantStorageError.photoMissing), .failure(PlantStorageError.photoCorrupt), .success(Data("invalid".utf8))] {
            let repository = DetailRepository()
            let vm = model(1, repository)
            let initial = Task { await vm.load() }
            await repository.wait(count: 1)
            await repository.resolvePhoto(0, result)
            await initial.value
            assertPlant(vm, 1)
            guard case .failed = vm.photoState else { return XCTFail("Photo failure hidden") }
            let retry = Task { await vm.retryPhoto() }
            await repository.wait(count: 2)
            await vm.retryPhoto() // Double tap ignored.
            await repository.resolvePhoto(1, .failure(PlantStorageError.photoMissing))
            await retry.value
            guard case .failed = vm.photoState else { return XCTFail("Persistent failure hidden") }
            let recover = Task { await vm.retryPhoto() }
            await repository.wait(count: 3)
            await repository.resolvePhoto(2, .success(StorageTestFixture.photo(1)))
            await recover.value
            guard case .loaded = vm.photoState else { return XCTFail("Actual image not recovered") }
            assertPlant(vm, 1)
            let counts = await repository.counts()
            XCTAssertEqual(counts.0, 1)
            XCTAssertEqual(counts.1, [vm.id, vm.id, vm.id])
            XCTAssertEqual(counts.2, 0)
        }
    }

    func testMissingMetadataAndStorageErrorNeverRequestPhoto() async {
        let absent = DetailRepository(plants: [])
        let missing = model(1, absent)
        await missing.load()
        guard case .notFound = missing.state else { return XCTFail("Expected notFound") }
        let broken = DetailRepository(failure: .storage)
        let failed = model(1, broken)
        await failed.load()
        guard case .failed = failed.state else { return XCTFail("Expected local failure") }
        let a = await absent.counts(), b = await broken.counts()
        XCTAssertTrue(a.1.isEmpty && b.1.isEmpty)
    }

    func testCancelledMetadataResponseCannotReplaceNewState() async {
        let repository = DetailRepository(suspendMetadata: true)
        let vm = model(1, repository)
        let old = Task { await vm.load() }
        await repository.wait(metadata: true, count: 1)
        await vm.load() // Duplicate metadata request ignored.
        vm.cancelLoading()
        let current = Task { await vm.load() }
        await repository.wait(metadata: true, count: 2)
        await repository.resolveMetadata(1, .success([StorageTestFixture.plant(1)]))
        await repository.wait(count: 1)
        await repository.resolvePhoto(0, .success(StorageTestFixture.photo(1)))
        await current.value
        await repository.resolveMetadata(0, .failure(PlantStorageError.storage))
        await old.value
        assertPlant(vm, 1)
        guard case .loaded = vm.photoState else { return XCTFail("Old metadata changed photo") }
    }

    func testLatePhotoAndCancelledTaskDoNotShowFailureOrReplaceImage() async {
        let repository = DetailRepository()
        let vm = model(1, repository)
        let old = Task { await vm.load() }
        await repository.wait(count: 1)
        vm.cancelLoading()
        let current = Task { await vm.load() }
        await repository.wait(count: 2)
        await repository.resolvePhoto(1, .success(StorageTestFixture.photo(1)))
        await current.value
        guard case .loaded(let expected) = vm.photoState else { return XCTFail("Missing image") }
        await repository.resolvePhoto(0, .success(StorageTestFixture.photo(2)))
        await old.value
        guard case .loaded(let actual) = vm.photoState else { return XCTFail("Late response changed state") }
        XCTAssertTrue(actual === expected)
        let other = model(2, repository)
        let cancelled = Task { await other.load() }
        await repository.wait(count: 3)
        cancelled.cancel()
        await repository.resolvePhoto(2, .failure(CancellationError()))
        await cancelled.value
        assertPlant(other, 2)
        guard case .idle = other.photoState else { return XCTFail("Cancellation visible") }
    }

    func testTaskMetadataCancellationIsReloadable() async {
        let repository = DetailRepository(suspendMetadata: true)
        let vm = model(1, repository)
        let task = Task { await vm.load() }
        await repository.wait(metadata: true, count: 1)
        task.cancel()
        await repository.resolveMetadata(0, .success([StorageTestFixture.plant(1)]))
        await task.value
        guard case .loading = vm.state else { return XCTFail("Cancellation visible") }
        let counts = await repository.counts()
        XCTAssertTrue(counts.1.isEmpty)
    }

    func testNavigatingFromPendingFirstToSecondIgnoresFirstResponse() async {
        let repository = DetailRepository(suspendMetadata: true)
        let first = model(1, repository), second = model(2, repository)
        let initialCounts = await repository.counts()
        XCTAssertEqual(initialCounts.0, 0) // Construction/factory never starts IO.
        XCTAssertTrue(initialCounts.1.isEmpty)
        let one = Task { await first.load() }
        await repository.wait(metadata: true, count: 1)
        first.cancelLoading()
        let two = Task { await second.load() }
        await repository.wait(metadata: true, count: 2)
        await repository.resolveMetadata(1, .success((1...2).map(StorageTestFixture.plant)))
        await repository.wait(count: 1)
        await repository.resolvePhoto(0, .success(StorageTestFixture.photo(2)))
        await two.value
        await repository.resolveMetadata(0, .success((1...2).map(StorageTestFixture.plant)))
        await one.value
        assertPlant(second, 2)
        guard case .loading = first.state else { return XCTFail("Cancelled metadata applied") }
        let counts = await repository.counts()
        XCTAssertEqual(counts.1, [second.id])
    }

    func testBoundedImageAndPersistedDatesAndBlankLocation() async {
        let repository = DetailRepository()
        let vm = model(1, repository)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let bytes = UIGraphicsImageRenderer(size: CGSize(width: 2400, height: 1800), format: format)
            .image { $0.fill(CGRect(x: 0, y: 0, width: 2400, height: 1800)) }.jpegData(compressionQuality: 0.8)!
        let task = Task { await vm.load() }
        await repository.wait(count: 1)
        await repository.resolvePhoto(0, .success(bytes))
        await task.value
        guard case .loaded(let image) = vm.photoState else { return XCTFail("Image missing") }
        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 1600)
        let utc = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(PlantDetailViewModel.formattedDate(StorageTestFixture.plant(1).createdAt, timeZone: utc), "1 de enero de 1970")
        XCTAssertEqual(PlantDetailViewModel.formattedDate(Date(timeIntervalSince1970: 86400), timeZone: utc), "2 de enero de 1970")
        XCTAssertNil(PlantDetailViewModel.visibleLocation(nil))
        XCTAssertNil(PlantDetailViewModel.visibleLocation(" \n"))
        XCTAssertEqual(PlantDetailViewModel.visibleLocation("  Ventana  "), "  Ventana  ")
    }
}
