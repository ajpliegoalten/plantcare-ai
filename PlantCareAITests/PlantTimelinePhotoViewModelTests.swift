import XCTest
import UIKit
import Combine
@testable import PlantCareAI

@MainActor
final class PlantTimelinePhotoViewModelTests: XCTestCase {
    private func wait(_ condition: () -> Bool) async {
        for _ in 0..<1000 { if condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
    private func entries(_ plantID: UUID) -> [PlantTimelineEntry] {
        (1...5).map { .additional(PlantPhoto(id: PlantTimelineFixtureLoad.id($0), plantID: plantID,
            occurredAt: Date(timeIntervalSince1970: 86400), createdAt: Date(timeIntervalSince1970: 100000),
            timeZoneIdentifier: "Etc/UTC", width: 640, height: 480)) }
    }
    func testDemandDedupTwoInFlightBoundedLRUFailureRetryOwnIdentityAndNoReloadLoop() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, plantID in
            XCTAssertEqual(plantID, id); return try await gate.read(identity)
        }, decode: { _ in image })
        vm.appear(); vm.setEntries(values)
        let initialCount = await gate.count; XCTAssertEqual(initialCount, 0)
        vm.show(values[0].id); vm.show(values[0].id); vm.show(values[1].id); vm.show(values[2].id)
        await gate.waitCount(2); XCTAssertEqual(vm.inFlightCount, 2)
        await gate.finish(0, .success(Data())); await gate.waitCount(3)
        await gate.finish(1, .failure(PlantPhotoError.photoMissing))
        await wait { vm.state(for: values[1].id) == .failed }
        XCTAssertEqual(vm.state(for: values[0].id), .loaded)
        vm.retry(values[1].id); await gate.waitCount(4)
        await gate.finish(2, .success(Data())); await gate.finish(3, .success(Data()))
        await wait { vm.cachedCount == 3 }
        vm.show(values[3].id); await gate.waitCount(5); await gate.finish(4, .success(Data()))
        await wait { vm.state(for: values[3].id) == .loaded }
        XCTAssertEqual(vm.cachedCount, 3); XCTAssertNil(vm.image(for: values[0].id))
        XCTAssertEqual(vm.state(for: values[0].id), .idle)
        let count = await gate.count; XCTAssertEqual(count, 5) // No eviction hot-loop.
        vm.hide(values[0].id); vm.show(values[0].id); await gate.waitCount(6)
        await gate.finish(5, .success(Data())); await wait { vm.state(for: values[0].id) == .loaded }
        vm.disappear(); XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.states, [:])
    }
    func testEvictionPreservesOnscreenPhotosInsteadOfRecentlyHiddenRows() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values)
        for index in 0..<3 {
            vm.show(values[index].id); await gate.waitCount(index + 1)
            await gate.finish(index, .success(Data())); await wait { vm.state(for: values[index].id) == .loaded }
        }
        // Lazy containers can retain mounted rows. Only C actually left the viewport;
        // A/B are still onscreen even though C was the most recently decoded image.
        vm.hide(values[2].id); vm.show(values[3].id); await gate.waitCount(4)
        await gate.finish(3, .success(Data())); await wait { vm.state(for: values[3].id) == .loaded }
        XCTAssertNotNil(vm.image(for: values[0].id))
        XCTAssertNotNil(vm.image(for: values[1].id))
        XCTAssertNil(vm.image(for: values[2].id))
        XCTAssertEqual(vm.cachedCount, 3)
        vm.disappear()
    }
    func testViewportReloadsMountedEvictedRowsAndKeepsImagesByIdentityWithoutAppearance() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let images = (0..<5).map { _ in UIImage() }
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in
            let index = values.firstIndex { $0.id == identity }!
            _ = try await gate.read(identity); return Data([UInt8(index)])
        }, decode: { images[Int($0.first!)] })
        func frames(_ offset: CGFloat) -> [PlantTimelineIdentity: CGRect] {
            Dictionary(uniqueKeysWithValues: values.enumerated().map {
                ($0.element.id, CGRect(x: 0, y: CGFloat($0.offset) * 300 - offset, width: 300, height: 300))
            })
        }
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)
        vm.appear(); vm.setEntries(values); vm.updateViewport(frames: frames(0), bounds: bounds)
        await gate.waitCount(2); await gate.finish(0, .success(Data())); await gate.finish(1, .success(Data()))
        await wait { vm.cachedCount == 2 }
        XCTAssertTrue(vm.image(for: values[0].id) === images[0]); XCTAssertTrue(vm.image(for: values[1].id) === images[1])
        vm.updateViewport(frames: frames(600), bounds: bounds)
        await gate.waitCount(4); await gate.finish(2, .success(Data())); await gate.finish(3, .success(Data()))
        await wait { vm.state(for: values[2].id) == .loaded && vm.state(for: values[3].id) == .loaded }
        XCTAssertLessThanOrEqual(vm.cachedCount, 3)
        XCTAssertTrue(vm.image(for: values[2].id) === images[2]); XCTAssertTrue(vm.image(for: values[3].id) === images[3])
        XCTAssertEqual(values.prefix(2).filter { vm.image(for: $0.id) == nil }.count, 1)
        // Same mounted frame identities return to the viewport, no appearance call.
        vm.updateViewport(frames: frames(0), bounds: bounds)
        await gate.waitCount(5); await gate.finish(4, .success(Data()))
        await wait { vm.state(for: values[0].id) == .loaded && vm.state(for: values[1].id) == .loaded }
        XCTAssertTrue(vm.image(for: values[0].id) === images[0]); XCTAssertTrue(vm.image(for: values[1].id) === images[1])
        vm.updateViewport(frames: frames(0), bounds: bounds)
        let count = await gate.count; XCTAssertEqual(count, 5) // Stationary viewport never loops.
        vm.updateViewport(frames: [:], bounds: bounds); vm.disappear()
    }

    func testViewportCapsDemandAndRevisitedCancelledReadDrainsBeforeReload() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)
        let frames = Dictionary(uniqueKeysWithValues: values.enumerated().map {
            ($0.element.id, CGRect(x: 0, y: CGFloat($0.offset) * 100, width: 300, height: 100))
        })
        vm.appear(); vm.setEntries(values); vm.updateViewport(frames: frames, bounds: bounds)
        await gate.waitCount(2); XCTAssertEqual(vm.inFlightCount, 2)
        vm.updateViewport(frames: [:], bounds: bounds)
        // Observe cancellation explicitly; a fixed number of yields does not guarantee
        // when deferred hides ran on the executor, and reads deliberately keep draining.
        guard await gate.waitCancellationCount(2) else { vm.disappear(); return }
        vm.updateViewport(frames: frames, bounds: bounds)
        XCTAssertEqual(vm.inFlightCount, 2)
        await gate.finish(0, .success(Data())); await gate.finish(1, .success(Data()))
        await gate.waitCount(4)
        await gate.finish(2, .success(Data())); await gate.finish(3, .success(Data()))
        await gate.waitCount(5); await gate.finish(4, .success(Data()))
        await wait { vm.cachedCount == 3 && vm.inFlightCount == 0 }
        XCTAssertNotNil(vm.image(for: values[0].id)); XCTAssertNotNil(vm.image(for: values[1].id)); XCTAssertNotNil(vm.image(for: values[2].id))
        XCTAssertNil(vm.image(for: values[3].id)); XCTAssertNil(vm.image(for: values[4].id))
        let count = await gate.count; XCTAssertEqual(count, 5)
        vm.disappear()
    }

    func testGeometryCoalescesOutsideLayoutAndUnchangedVisibleSetDoesNotRepublishLoading() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)
        let frames = [values[0].id: CGRect(x: 0, y: 0, width: 300, height: 300),
                      values[1].id: CGRect(x: 0, y: 300, width: 300, height: 300)]
        vm.appear(); vm.setEntries(values)
        var publications = 0
        let subscription = vm.objectWillChange.sink { publications += 1 }
        vm.scheduleViewport(frames: frames, bounds: bounds)
        vm.scheduleViewport(frames: [:], bounds: bounds)
        vm.scheduleViewport(frames: frames, bounds: bounds)
        XCTAssertEqual(publications, 0); XCTAssertEqual(vm.inFlightCount, 0)
        await gate.waitCount(2)
        let loadingPublications = publications
        for offset in 1...20 {
            let shifted = frames.mapValues { $0.offsetBy(dx: 0, dy: CGFloat(offset) * 0.01) }
            vm.updateViewport(frames: shifted, bounds: bounds)
            vm.show(values[0].id) // Same in-flight identity must not republish either.
        }
        XCTAssertEqual(publications, loadingPublications)
        XCTAssertEqual(vm.inFlightCount, 2)
        await gate.finish(0, .success(Data())); await gate.finish(1, .success(Data()))
        await wait { vm.cachedCount == 2 }
        vm.scheduleViewport(frames: frames, bounds: bounds); vm.disappear()
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.states, [:]); XCTAssertEqual(vm.inFlightCount, 0)
        let count = await gate.count; XCTAssertEqual(count, 2)
        withExtendedLifetime(subscription) {}
    }

    func testMetadataRefreshReloadsLastViewportWithoutNewGeometryAndRealExitClearsIt() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)
        let frames = [values[0].id: CGRect(x: 0, y: 0, width: 300, height: 300),
                      values[1].id: CGRect(x: 0, y: 300, width: 300, height: 300)]
        vm.appear(); vm.setEntries(values); vm.scheduleViewport(frames: frames, bounds: bounds)
        await gate.waitCount(2); await gate.finish(0, .success(Data())); await gate.finish(1, .success(Data()))
        await wait { vm.cachedCount == 2 }
        vm.reset(preservingViewport: true); XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.states, [:])
        vm.setEntries(values) // No geometry/row-appearance callback after fast refresh.
        await gate.waitCount(4); await gate.finish(2, .success(Data())); await gate.finish(3, .success(Data()))
        await wait { vm.cachedCount == 2 }
        XCTAssertTrue(vm.image(for: values[0].id) === image); XCTAssertTrue(vm.image(for: values[1].id) === image)
        vm.reset(preservingViewport: true); vm.setEntries(entries(StorageTestFixture.plant(2).id))
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.inFlightCount, 0)
        vm.disappear(); vm.appear(); vm.setEntries(values)
        for _ in 0..<10 { await Task.yield() }
        let count = await gate.count; XCTAssertEqual(count, 4) // Real exit cannot reuse old visibility.
        XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.inFlightCount, 0); vm.disappear()
    }

    func testCancelDrainsBeforeNewSessionNeverExceedsTwoAndLateBytesNeverPublish() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id); vm.show(values[1].id); await gate.waitCount(2)
        vm.hide(values[0].id); vm.show(values[2].id)
        XCTAssertEqual(vm.inFlightCount, 2)
        vm.disappear(); vm.appear(); vm.setEntries(values); vm.show(values[4].id)
        XCTAssertEqual(vm.inFlightCount, 2); XCTAssertEqual(vm.cachedCount, 0)
        await gate.finish(0, .success(Data())); await gate.waitCount(3)
        XCTAssertEqual(vm.inFlightCount, 2)
        await gate.finish(1, .success(Data())); await gate.finish(2, .success(Data()))
        await wait { vm.state(for: values[4].id) == .loaded }
        XCTAssertNil(vm.image(for: values[0].id)); XCTAssertNil(vm.image(for: values[1].id)); XCTAssertEqual(vm.cachedCount, 1)
        vm.disappear()
    }
    func testActualThumbnailMax1600CorruptOwnErrorAndForeignRowsNeverRead() async throws {
        let id = StorageTestFixture.plant(1).id
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { _, _ in Data("broken".utf8) })
        vm.appear(); vm.setEntries(entries(StorageTestFixture.plant(2).id)); vm.show(.additional(PlantTimelineFixtureLoad.id(1)))
        XCTAssertEqual(vm.inFlightCount, 0)
        let values = entries(id); vm.setEntries(values); vm.show(values[0].id)
        await wait { vm.state(for: values[0].id) == .failed }
        XCTAssertEqual(vm.state(for: values[1].id), .idle); vm.disappear()
        let image = try await PlantTimelinePhotoViewModel.thumbnail(StorageTestFixture.photo(1))
        XCTAssertLessThanOrEqual(max(image.cgImage!.width, image.cgImage!.height), 1600)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let large = UIGraphicsImageRenderer(size: CGSize(width: 2048, height: 1800), format: format).image { context in
            UIColor.green.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2048, height: 1800))
        }.jpegData(compressionQuality: 0.85)!
        let bounded = try await PlantTimelinePhotoViewModel.thumbnail(large)
        XCTAssertEqual(bounded.cgImage?.width, 1600)
        XCTAssertLessThanOrEqual(bounded.cgImage!.height, 1600)
    }

    func testCancelledDecodeCannotPublishAndDifferentPlantSessionDoesNotShareCache() async {
        let a = StorageTestFixture.plant(1).id, b = StorageTestFixture.plant(2).id, decode = TimelineImageGate()
        let values = entries(a), image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: a, read: { _, id in XCTAssertEqual(id, a); return Data() },
            decode: { _ in _ = try await decode.read(.initial(a)); return image })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id); await decode.waitCount(1)
        vm.hide(values[0].id); await decode.finish(0, .success(Data())); await wait { vm.inFlightCount == 0 }
        XCTAssertNil(vm.image(for: values[0].id)); XCTAssertEqual(vm.state(for: values[0].id), .idle)
        let other = PlantTimelinePhotoViewModel(plantID: b, read: { _, id in XCTAssertEqual(id, b); return Data() }, decode: { _ in image })
        other.appear(); other.setEntries(entries(b)); other.show(values[0].id)
        await wait { other.cachedCount == 1 }; XCTAssertEqual(vm.cachedCount, 0)
        vm.disappear(); other.disappear()
    }

    func testReparentedGroupOwnersRetainSingleInFlightReadWithoutReload() async {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), image = UIImage()
        let values = entries(StorageTestFixture.plant(1).id), oldOwner = UUID(), newOwner = UUID()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id, owner: oldOwner); await gate.waitCount(1)
        // Remove-before-insert during day regrouping, then an overlapping old owner.
        vm.hide(values[0].id, owner: oldOwner); vm.show(values[0].id, owner: newOwner)
        vm.show(values[0].id, owner: oldOwner); vm.hide(values[0].id, owner: oldOwner)
        await gate.finish(0, .success(Data())); await wait { vm.state(for: values[0].id) == .loaded }
        let count = await gate.count; XCTAssertEqual(count, 1)
        XCTAssertEqual(vm.cachedCount, 1); vm.hide(values[0].id, owner: newOwner)
        vm.show(values[0].id, owner: UUID()); XCTAssertEqual(vm.cachedCount, 1)
        vm.disappear()
    }
}

actor TimelineImageGate {
    private var continuations: [CheckedContinuation<Data, Error>] = []
    private var cancellations = 0
    var count: Int { continuations.count }
    func read(_ id: PlantTimelineIdentity) async throws -> Data {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuations.append($0) }
        }, onCancel: { Task { await self.recordCancellation() } })
    }
    private func recordCancellation() { cancellations += 1 }
    func waitCancellationCount(_ count: Int) async -> Bool {
        for _ in 0..<1000 {
            if cancellations >= count { return true }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("Timed out waiting for cancellation"); return false
    }
    func finish(_ index: Int, _ result: Result<Data, Error>) {
        guard continuations.indices.contains(index) else { XCTFail("Request \(index) does not exist"); return }
        continuations[index].resume(with: result)
    }
    func waitCount(_ count: Int) async {
        for _ in 0..<1000 { if continuations.count >= count { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
}
