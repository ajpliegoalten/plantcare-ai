import XCTest
import UIKit
import Combine
@testable import PlantCareAI

@MainActor
final class PlantTimelinePhotoViewModelTests: XCTestCase {
    func testGateRejectsUnknownWrongIdentityAndDuplicateTokensWithoutResumingWrongRead() async throws {
        let identity = PlantTimelineIdentity.additional(PlantTimelineFixtureLoad.id(1)), gate = TimelineImageGate()
        let read = Task { try await gate.read(identity) }
        let request = try await gate.waitRegistration(for: identity)
        for invalid in [TimelineImageGate.Request(token: UUID(), identity: identity, occurrence: 0),
                        TimelineImageGate.Request(token: request.token, identity: .initial(UUID()), occurrence: 0)] {
            do { try await gate.finish(invalid, .success(Data())); XCTFail("Unknown request accepted") }
            catch { XCTAssertEqual(error as? TimelineImageGate.GateError, .unknownRequest) }
        }
        let payload = Data([42])
        try await gate.finish(request, .success(payload))
        let actual = try await read.value; XCTAssertEqual(actual, payload)
        do { try await gate.finish(request, .success(Data())); XCTFail("Duplicate completion accepted") }
        catch { XCTAssertEqual(error as? TimelineImageGate.GateError, .alreadyCompleted) }
        let count = await gate.count; XCTAssertEqual(count, 1)
    }
    func testPurgedIdentityInLateViewportPreferencesCannotReadOrRepublish() async throws {
        let id = StorageTestFixture.plant(1).id, values = entries(StorageTestFixture.plant(1).id), gate = TimelineImageGate()
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values); vm.remove(values[0].id)
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)
        vm.scheduleViewport(frames: [values[0].id: bounds, values[1].id: bounds], bounds: bounds)
        await gate.waitCount(1); try await gate.finish(values[1].id, .success(Data())); await wait { vm.inFlightCount == 0 }
        XCTAssertNil(vm.image(for: values[0].id)); XCTAssertEqual(vm.state(for: values[0].id), .idle)
        XCTAssertNotNil(vm.image(for: values[1].id)); let count = await gate.count; XCTAssertEqual(count, 1); vm.disappear()
    }
    func testDeletionPurgesCachedQueuedOwnersViewportAndRejectsLateReadWhileDraining() async throws {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values)
        vm.show(values[0].id); await gate.waitCount(1); try await gate.finish(values[0].id, .success(Data()))
        await wait { vm.cachedCount == 1 }
        vm.show(values[1].id); vm.show(values[2].id); vm.show(values[3].id); await gate.waitCount(3)
        vm.remove(values[0].id); vm.remove(values[1].id); vm.remove(values[3].id)
        XCTAssertNil(vm.image(for: values[0].id)); XCTAssertEqual(vm.state(for: values[0].id), .idle)
        XCTAssertEqual(vm.inFlightCount, 2)
        vm.show(values[1].id); vm.show(values[3].id)
        try await gate.finish(values[1].id, .success(Data())); try await gate.finish(values[2].id, .success(Data()))
        await wait { vm.inFlightCount == 0 }
        XCTAssertNil(vm.image(for: values[1].id)); XCTAssertNil(vm.image(for: values[3].id))
        XCTAssertNotNil(vm.image(for: values[2].id)); XCTAssertEqual(vm.cachedCount, 1)
        let count = await gate.count; XCTAssertEqual(count, 3); vm.disappear()
    }

    func testDeletionDuringDecodeCannotRepublishAndSurvivingViewportStillLoads() async throws {
        let id = StorageTestFixture.plant(1).id, decode = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in
            Data([UInt8(values.firstIndex { $0.id == identity }!)])
        }, decode: { data in
            _ = try await decode.read(values[Int(data.first!)].id); return image
        })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id); await decode.waitCount(1)
        vm.remove(values[0].id); vm.show(values[1].id); await decode.waitCount(2)
        try await decode.finish(values[0].id, .success(Data())); try await decode.finish(values[1].id, .success(Data()))
        await wait { vm.inFlightCount == 0 }
        XCTAssertNil(vm.image(for: values[0].id)); XCTAssertEqual(vm.state(for: values[0].id), .idle)
        XCTAssertNotNil(vm.image(for: values[1].id)); vm.disappear()
    }
    private func wait(_ condition: () -> Bool) async {
        for _ in 0..<1000 { if condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
    private func entries(_ plantID: UUID) -> [PlantTimelineEntry] {
        (1...5).map { .additional(PlantPhoto(id: PlantTimelineFixtureLoad.id($0), plantID: plantID,
            occurredAt: Date(timeIntervalSince1970: 86400), createdAt: Date(timeIntervalSince1970: 100000),
            timeZoneIdentifier: "Etc/UTC", width: 640, height: 480)) }
    }
    func testDemandDedupTwoInFlightBoundedLRUFailureRetryOwnIdentityAndNoReloadLoop() async throws {
        try await verifyDemand(registrationOrder: [])
    }

    func testDemandReversedArrivalKeepsOwnFailureRetryCacheAndConcurrency() async throws {
        try await verifyDemand(registrationOrder: [.additional(PlantTimelineFixtureLoad.id(2)), .additional(PlantTimelineFixtureLoad.id(1))])
    }

    private func verifyDemand(registrationOrder: [PlantTimelineIdentity]) async throws {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(registrationOrder: registrationOrder), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, plantID in
            XCTAssertEqual(plantID, id); return try await gate.read(identity)
        }, decode: { _ in image })
        vm.appear(); vm.setEntries(values)
        let initialCount = await gate.count; XCTAssertEqual(initialCount, 0)
        vm.show(values[0].id); vm.show(values[0].id); vm.show(values[1].id); vm.show(values[2].id)
        await gate.waitCount(2); XCTAssertEqual(vm.inFlightCount, 2)
        let first = try await gate.waitRegistration(for: values[0].id)
        let second = try await gate.waitRegistration(for: values[1].id)
        if !registrationOrder.isEmpty {
            let actual = await gate.registrations.map(\.identity)
            XCTAssertEqual(Array(actual.prefix(2)), registrationOrder)
            XCTAssertEqual(actual.count, 2)
        }
        try await gate.finish(first, .success(Data())); await gate.waitCount(3)
        try await gate.finish(second, .failure(PlantPhotoError.photoMissing))
        await wait { vm.state(for: values[1].id) == .failed }
        XCTAssertEqual(vm.state(for: values[0].id), .loaded)
        vm.retry(values[1].id); await gate.waitCount(4)
        try await gate.finish(values[2].id, .success(Data())); try await gate.finish(values[1].id, occurrence: 1, .success(Data()))
        await wait { vm.cachedCount == 3 }
        vm.show(values[3].id); await gate.waitCount(5); try await gate.finish(values[3].id, .success(Data()))
        await wait { vm.state(for: values[3].id) == .loaded }
        XCTAssertEqual(vm.cachedCount, 3); XCTAssertNil(vm.image(for: values[0].id))
        XCTAssertEqual(vm.state(for: values[0].id), .idle)
        let count = await gate.count; XCTAssertEqual(count, 5) // No eviction hot-loop.
        vm.hide(values[0].id); vm.show(values[0].id); await gate.waitCount(6)
        try await gate.finish(values[0].id, occurrence: 1, .success(Data())); await wait { vm.state(for: values[0].id) == .loaded }
        vm.disappear(); XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.states, [:])
    }
    func testEvictionPreservesOnscreenPhotosInsteadOfRecentlyHiddenRows() async throws {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values)
        for index in 0..<3 {
            vm.show(values[index].id); await gate.waitCount(index + 1)
            try await gate.finish(values[index].id, .success(Data())); await wait { vm.state(for: values[index].id) == .loaded }
        }
        // Lazy containers can retain mounted rows. Only C actually left the viewport;
        // A/B are still onscreen even though C was the most recently decoded image.
        vm.hide(values[2].id); vm.show(values[3].id); await gate.waitCount(4)
        try await gate.finish(values[3].id, .success(Data())); await wait { vm.state(for: values[3].id) == .loaded }
        XCTAssertNotNil(vm.image(for: values[0].id))
        XCTAssertNotNil(vm.image(for: values[1].id))
        XCTAssertNil(vm.image(for: values[2].id))
        XCTAssertEqual(vm.cachedCount, 3)
        vm.disappear()
    }
    func testViewportReloadsMountedEvictedRowsAndKeepsImagesByIdentityWithoutAppearance() async throws {
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
        await gate.waitCount(2); try await gate.finish(values[0].id, .success(Data())); try await gate.finish(values[1].id, .success(Data()))
        await wait { vm.cachedCount == 2 }
        XCTAssertTrue(vm.image(for: values[0].id) === images[0]); XCTAssertTrue(vm.image(for: values[1].id) === images[1])
        vm.updateViewport(frames: frames(600), bounds: bounds)
        await gate.waitCount(4); try await gate.finish(values[2].id, .success(Data())); try await gate.finish(values[3].id, .success(Data()))
        await wait { vm.state(for: values[2].id) == .loaded && vm.state(for: values[3].id) == .loaded }
        XCTAssertLessThanOrEqual(vm.cachedCount, 3)
        XCTAssertTrue(vm.image(for: values[2].id) === images[2]); XCTAssertTrue(vm.image(for: values[3].id) === images[3])
        XCTAssertEqual(values.prefix(2).filter { vm.image(for: $0.id) == nil }.count, 1)
        let evicted = try XCTUnwrap(values.prefix(2).first { vm.image(for: $0.id) == nil })
        // Same mounted frame identities return to the viewport, no appearance call.
        vm.updateViewport(frames: frames(0), bounds: bounds)
        await gate.waitCount(5); try await gate.finish(evicted.id, occurrence: 1, .success(Data()))
        await wait { vm.state(for: values[0].id) == .loaded && vm.state(for: values[1].id) == .loaded }
        XCTAssertTrue(vm.image(for: values[0].id) === images[0]); XCTAssertTrue(vm.image(for: values[1].id) === images[1])
        vm.updateViewport(frames: frames(0), bounds: bounds)
        let count = await gate.count; XCTAssertEqual(count, 5) // Stationary viewport never loops.
        vm.updateViewport(frames: [:], bounds: bounds); vm.disappear()
    }

    func testViewportCapsDemandAndRevisitedCancelledReadDrainsBeforeReload() async throws {
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
        try await gate.finish(values[0].id, .success(Data())); try await gate.finish(values[1].id, .success(Data()))
        await gate.waitCount(4)
        let firstWave = await gate.pendingRequests
        XCTAssertEqual(firstWave.count, 2)
        XCTAssertTrue(firstWave.contains { $0.identity == values[2].id && $0.occurrence == 0 })
        XCTAssertEqual(firstWave.filter { $0.occurrence == 1 && [values[0].id, values[1].id].contains($0.identity) }.count, 1)
        for request in firstWave { try await gate.finish(request, .success(Data())) }
        await gate.waitCount(5)
        let lastWave = await gate.pendingRequests
        XCTAssertEqual(lastWave.count, 1)
        let last = try XCTUnwrap(lastWave.first)
        XCTAssertEqual(last.occurrence, 1); XCTAssertTrue([values[0].id, values[1].id].contains(last.identity))
        try await gate.finish(last, .success(Data()))
        await wait { vm.cachedCount == 3 && vm.inFlightCount == 0 }
        XCTAssertNotNil(vm.image(for: values[0].id)); XCTAssertNotNil(vm.image(for: values[1].id)); XCTAssertNotNil(vm.image(for: values[2].id))
        XCTAssertNil(vm.image(for: values[3].id)); XCTAssertNil(vm.image(for: values[4].id))
        let count = await gate.count; XCTAssertEqual(count, 5)
        vm.disappear()
    }

    func testGeometryCoalescesOutsideLayoutAndUnchangedVisibleSetDoesNotRepublishLoading() async throws {
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
        try await gate.finish(values[0].id, .success(Data())); try await gate.finish(values[1].id, .success(Data()))
        await wait { vm.cachedCount == 2 }
        vm.scheduleViewport(frames: frames, bounds: bounds); vm.disappear()
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.states, [:]); XCTAssertEqual(vm.inFlightCount, 0)
        let count = await gate.count; XCTAssertEqual(count, 2)
        withExtendedLifetime(subscription) {}
    }

    func testMetadataRefreshReloadsLastViewportWithoutNewGeometryAndRealExitClearsIt() async throws {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 600)
        let frames = [values[0].id: CGRect(x: 0, y: 0, width: 300, height: 300),
                      values[1].id: CGRect(x: 0, y: 300, width: 300, height: 300)]
        vm.appear(); vm.setEntries(values); vm.scheduleViewport(frames: frames, bounds: bounds)
        await gate.waitCount(2); try await gate.finish(values[0].id, .success(Data())); try await gate.finish(values[1].id, .success(Data()))
        await wait { vm.cachedCount == 2 }
        vm.reset(preservingViewport: true); XCTAssertEqual(vm.cachedCount, 0); XCTAssertEqual(vm.states, [:])
        vm.setEntries(values) // No geometry/row-appearance callback after fast refresh.
        await gate.waitCount(4); try await gate.finish(values[0].id, occurrence: 1, .success(Data())); try await gate.finish(values[1].id, occurrence: 1, .success(Data()))
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

    func testCancelDrainsBeforeNewSessionNeverExceedsTwoAndLateBytesNeverPublish() async throws {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), values = entries(StorageTestFixture.plant(1).id)
        let image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id); vm.show(values[1].id); await gate.waitCount(2)
        vm.hide(values[0].id); vm.show(values[2].id)
        XCTAssertEqual(vm.inFlightCount, 2)
        vm.disappear(); vm.appear(); vm.setEntries(values); vm.show(values[4].id)
        XCTAssertEqual(vm.inFlightCount, 2); XCTAssertEqual(vm.cachedCount, 0)
        try await gate.finish(values[0].id, .success(Data())); await gate.waitCount(3)
        XCTAssertEqual(vm.inFlightCount, 2)
        try await gate.finish(values[1].id, .success(Data())); try await gate.finish(values[4].id, .success(Data()))
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

    func testCancelledDecodeCannotPublishAndDifferentPlantSessionDoesNotShareCache() async throws {
        let a = StorageTestFixture.plant(1).id, b = StorageTestFixture.plant(2).id, decode = TimelineImageGate()
        let values = entries(a), image = UIImage()
        let vm = PlantTimelinePhotoViewModel(plantID: a, read: { _, id in XCTAssertEqual(id, a); return Data() },
            decode: { _ in _ = try await decode.read(values[0].id); return image })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id); await decode.waitCount(1)
        vm.hide(values[0].id); try await decode.finish(values[0].id, .success(Data())); await wait { vm.inFlightCount == 0 }
        XCTAssertNil(vm.image(for: values[0].id)); XCTAssertEqual(vm.state(for: values[0].id), .idle)
        let other = PlantTimelinePhotoViewModel(plantID: b, read: { _, id in XCTAssertEqual(id, b); return Data() }, decode: { _ in image })
        other.appear(); other.setEntries(entries(b)); other.show(values[0].id)
        await wait { other.cachedCount == 1 }; XCTAssertEqual(vm.cachedCount, 0)
        vm.disappear(); other.disappear()
    }

    func testReparentedGroupOwnersRetainSingleInFlightReadWithoutReload() async throws {
        let id = StorageTestFixture.plant(1).id, gate = TimelineImageGate(), image = UIImage()
        let values = entries(StorageTestFixture.plant(1).id), oldOwner = UUID(), newOwner = UUID()
        let vm = PlantTimelinePhotoViewModel(plantID: id, read: { identity, _ in try await gate.read(identity) }, decode: { _ in image })
        vm.appear(); vm.setEntries(values); vm.show(values[0].id, owner: oldOwner); await gate.waitCount(1)
        // Remove-before-insert during day regrouping, then an overlapping old owner.
        vm.hide(values[0].id, owner: oldOwner); vm.show(values[0].id, owner: newOwner)
        vm.show(values[0].id, owner: oldOwner); vm.hide(values[0].id, owner: oldOwner)
        try await gate.finish(values[0].id, .success(Data())); await wait { vm.state(for: values[0].id) == .loaded }
        let count = await gate.count; XCTAssertEqual(count, 1)
        XCTAssertEqual(vm.cachedCount, 1); vm.hide(values[0].id, owner: newOwner)
        vm.show(values[0].id, owner: UUID()); XCTAssertEqual(vm.cachedCount, 1)
        vm.disappear()
    }
}

actor TimelineImageGate {
    struct Request: Hashable, Sendable {
        let token: UUID
        let identity: PlantTimelineIdentity
        let occurrence: Int
    }
    enum GateError: Error, Equatable { case unknownRequest, alreadyCompleted, registrationTimedOut }
    private(set) var registrations: [Request] = []
    private var continuations: [UUID: CheckedContinuation<Data, Error>] = [:]
    // Test-only ordering of registration, never an ordering constraint on production.
    private let registrationOrder: [PlantTimelineIdentity]
    private var registrationWaiters: [CheckedContinuation<Void, Never>] = []
    init(registrationOrder: [PlantTimelineIdentity] = []) { self.registrationOrder = registrationOrder }
    private var cancellations = 0
    var count: Int { registrations.count }
    var pendingRequests: [Request] { registrations.filter { continuations[$0.token] != nil } }
    func read(_ id: PlantTimelineIdentity) async throws -> Data {
        try await withTaskCancellationHandler(operation: {
            if !registrations.contains(where: { $0.identity == id }), let position = registrationOrder.firstIndex(of: id) {
                let preceding = registrationOrder.prefix(position)
                while !preceding.allSatisfy({ identity in registrations.contains { $0.identity == identity } }) {
                    try Task.checkCancellation()
                    await withCheckedContinuation { registrationWaiters.append($0) }
                }
            }
            return try await withCheckedThrowingContinuation { continuation in
                let request = Request(token: UUID(), identity: id, occurrence: registrations.filter { $0.identity == id }.count)
                registrations.append(request); continuations[request.token] = continuation
                releaseRegistrationWaiters()
            }
        }, onCancel: { Task { await self.recordCancellation() } })
    }
    private func releaseRegistrationWaiters() {
        let waiting = registrationWaiters; registrationWaiters = []
        waiting.forEach { $0.resume() }
    }
    private func recordCancellation() {
        cancellations += 1; releaseRegistrationWaiters()
        // Registered IO deliberately keeps draining until its addressed completion.
        // Cancelling must not auto-resume it and hide a concurrency violation.
    }
    func waitCancellationCount(_ count: Int) async -> Bool {
        for _ in 0..<1000 {
            if cancellations >= count { return true }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("Timed out waiting for cancellation"); return false
    }
    func waitRegistration(for identity: PlantTimelineIdentity, occurrence: Int = 0) async throws -> Request {
        for _ in 0..<1000 {
            if let request = registrations.first(where: { $0.identity == identity && $0.occurrence == occurrence }) { return request }
            try await Task.sleep(for: .milliseconds(2))
        }
        throw GateError.registrationTimedOut
    }
    func finish(_ request: Request, _ result: Result<Data, Error>) throws {
        guard registrations.contains(request) else { throw GateError.unknownRequest }
        guard let continuation = continuations.removeValue(forKey: request.token) else { throw GateError.alreadyCompleted }
        continuation.resume(with: result)
    }
    func finish(_ identity: PlantTimelineIdentity, occurrence: Int = 0, _ result: Result<Data, Error>) async throws {
        let request = try await waitRegistration(for: identity, occurrence: occurrence)
        try finish(request, result)
    }
    func waitCount(_ count: Int) async {
        for _ in 0..<1000 { if registrations.count >= count { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
}
