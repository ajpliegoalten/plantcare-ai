import XCTest
@testable import PlantCareAI

@MainActor
final class PlantTimelineViewModelTests: XCTestCase {
    func testPhotoFailureWithoutLoadedJPEGDoesNotClaimImageReadableOrNotify() async {
        let plant = StorageTestFixture.plant(1), load = TimelineLoadGate(), photo = PlantTimelineFixtureLoad.photo(for: StorageTestFixture.plant(1).id)
        let loader = PlantTimelinePhotoViewModel(plantID: plant.id, read: { _, _ in throw PlantPhotoError.photoCorrupt })
        let vm = PlantTimelineViewModel(plantID: plant.id, load: load, photos: loader,
            deletePhoto: FailingTimelinePhotoDeletion(), onDeleted: { _ in XCTFail("Unconfirmed") })
        vm.appear(); await load.waitCount(1); await load.finish(0, .success([.initial(plant), .additional(photo)]))
        await wait { vm.state == .loaded }; loader.show(.additional(photo.id)); await wait { loader.state(for: .additional(photo.id)) == .failed }
        vm.requestDeletion(.additional(photo)); XCTAssertFalse(vm.deletionPhotoWasReadable)
        vm.confirmDeletion(); await wait { vm.deletionState == .failed }
        XCTAssertTrue(vm.entries.contains(.additional(photo))); XCTAssertFalse(vm.deletionPhotoWasReadable)
        vm.abandonDeletion(); XCTAssertNil(vm.deletionTarget); vm.disappear()
    }
    func testForegroundReadWhileConfirmingIsCancelledAndReconcilesAfterCommitWithoutResurrection() async {
        let plant = StorageTestFixture.plant(1), load = TimelineLoadGate(), writer = TimelineDeletionGate()
        let event = PlantTimelineFixtureLoad.events(for: plant.id)[0]
        var callbacks = 0
        let vm = PlantTimelineViewModel(plantID: plant.id, load: load,
            photos: PlantTimelinePhotoViewModel(plantID: plant.id, read: { _, _ in Data() }), deleteCare: writer,
            onDeleted: { _ in callbacks += 1 })
        vm.appear(); await load.waitCount(1); await load.finish(0, .success([.initial(plant), .care(event)]))
        await wait { vm.state == .loaded }; vm.requestDeletion(.care(event))
        vm.foreground(); await load.waitCount(2)
        // UIKit writes false before dispatching the destructive alert action.
        vm.showingDeletionConfirmation = false; vm.confirmDeletion(); await writer.waitCount(1)
        await writer.finish(0, .success(event)); await load.waitCount(3)
        await load.finish(1, .success([.initial(plant), .care(event)]))
        await load.finish(2, .success([.initial(plant)])); await wait { vm.state == .loaded }
        XCTAssertTrue(vm.noRecords); XCTAssertEqual(callbacks, 1); XCTAssertFalse(vm.showingDeletionConfirmation); vm.disappear()
    }
    func testPhotoDeletionPublishesCanonicalOncePurgesOwnImageAndKeepsCare() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
        let loader = PlantTimelinePhotoViewModel(plantID: fixture.plant.id, read: { _, _ in fixture.jpeg })
        var removed: [PlantTimelineEntry] = []
        let vm = PlantTimelineViewModel(plantID: fixture.plant.id,
            load: LoadPlantTimeline(detail: LoadPlantDetail(repository: repository), care: repository, photos: repository),
            photos: loader, deletePhoto: DeletePlantPhoto(repository: repository), onDeleted: { removed.append($0) })
        vm.appear(); await wait { vm.state == .loaded }
        loader.show(.additional(fixture.photo.id)); await wait { loader.cachedCount == 1 }
        vm.requestDeletion(.additional(fixture.photo)); XCTAssertTrue(vm.deletionPhotoWasReadable)
        vm.confirmDeletion(); vm.confirmDeletion(); await wait { vm.deletionState == .idle }
        XCTAssertEqual(removed, [.additional(fixture.photo)]); XCTAssertNil(loader.image(for: .additional(fixture.photo.id)))
        XCTAssertEqual(vm.entries.count, 6); XCTAssertTrue(vm.entries.contains(.care(fixture.events[0])))
        vm.disappear()
    }
    func testDeletionCancelFailureAbandonRetryAndDoubleTapNotifyOnce() async {
        let plant = StorageTestFixture.plant(1), load = TimelineLoadGate(), writer = TimelineDeletionGate()
        let event = PlantTimelineFixtureLoad.events(for: plant.id)[0]
        var callbacks: [PlantTimelineEntry] = []
        let vm = PlantTimelineViewModel(plantID: plant.id, load: load,
            photos: PlantTimelinePhotoViewModel(plantID: plant.id, read: { _, _ in XCTFail("No eager bytes"); return Data() }),
            deleteCare: writer, onDeleted: { callbacks.append($0) })
        vm.appear(); await load.waitCount(1); await load.finish(0, .success([.initial(plant), .care(event)]))
        await wait { vm.state == .loaded }
        vm.requestDeletion(.initial(plant)); XCTAssertEqual(vm.deletionState, .idle)
        vm.requestDeletion(.care(event)); XCTAssertEqual(vm.deletionState, .confirming)
        vm.abandonDeletion(); XCTAssertNil(vm.deletionTarget)
        let cancelledCount = await writer.count; XCTAssertEqual(cancelledCount, 0)
        XCTAssertEqual(callbacks, []); XCTAssertTrue(vm.entries.contains(.care(event)))
        vm.requestDeletion(.care(event)); vm.confirmDeletion(); vm.confirmDeletion()
        await writer.waitCount(1)
        await writer.finish(0, .failure(CareEventError.storage)); await wait { vm.deletionState == .failed }
        XCTAssertTrue(vm.entries.contains(.care(event))); XCTAssertEqual(callbacks, [])
        vm.abandonDeletion(); vm.confirmDeletion()
        let abandonedCount = await writer.count; XCTAssertEqual(abandonedCount, 1)
        vm.requestDeletion(.care(event)); vm.confirmDeletion(); await writer.waitCount(2)
        await writer.finish(1, .failure(CareEventError.storage)); await wait { vm.deletionState == .failed }
        vm.confirmDeletion(); await writer.waitCount(3)
        await writer.finish(2, .success(event)); await wait { vm.deletionState == .idle }
        XCTAssertEqual(callbacks, [.care(event)]); XCTAssertTrue(vm.noRecords)
        let payloads = await writer.expected; XCTAssertEqual(payloads, [event, event, event])
        vm.disappear()
    }

    func testForegroundDeferredDuringCommitAndSuccessSurvivesDeparture() async {
        let plant = StorageTestFixture.plant(1), load = TimelineLoadGate(), writer = TimelineDeletionGate()
        let event = PlantTimelineFixtureLoad.events(for: plant.id)[0]
        var callbacks = 0
        let vm = PlantTimelineViewModel(plantID: plant.id, load: load,
            photos: PlantTimelinePhotoViewModel(plantID: plant.id, read: { _, _ in Data() }),
            deleteCare: writer, onDeleted: { _ in callbacks += 1 })
        vm.appear(); await load.waitCount(1); await load.finish(0, .success([.initial(plant), .care(event)]))
        await wait { vm.state == .loaded }; vm.requestDeletion(.care(event)); vm.confirmDeletion()
        await writer.waitCount(1); vm.foreground(); vm.foreground()
        let count = await load.count; XCTAssertEqual(count, 1)
        vm.disappear(); await writer.finish(0, .success(event)); await wait { callbacks == 1 }
        XCTAssertEqual(vm.state, .idle); XCTAssertNil(vm.deletionTarget)
        vm.appear(); await load.waitCount(2); await load.finish(1, .success([.initial(plant)]))
        await wait { vm.state == .loaded }; XCTAssertTrue(vm.noRecords); vm.disappear()
    }

    func testObsoleteSnapshotReconcilesWithoutClaimingIntactOrSuccess() async {
        let plant = StorageTestFixture.plant(1), load = TimelineLoadGate(), writer = TimelineDeletionGate()
        let event = PlantTimelineFixtureLoad.events(for: plant.id)[0]
        let vm = PlantTimelineViewModel(plantID: plant.id, load: load,
            photos: PlantTimelinePhotoViewModel(plantID: plant.id, read: { _, _ in Data() }), deleteCare: writer,
            onDeleted: { _ in XCTFail("No confirmed commit") })
        vm.appear(); await load.waitCount(1); await load.finish(0, .success([.initial(plant), .care(event)]))
        await wait { vm.state == .loaded }; vm.requestDeletion(.care(event)); vm.confirmDeletion()
        await writer.waitCount(1); await writer.finish(0, .failure(CareEventError.notFound))
        await load.waitCount(2); XCTAssertTrue(vm.deletionNeedsReconciliation)
        vm.confirmDeletion(); let writes = await writer.count; XCTAssertEqual(writes, 1)
        await load.finish(1, .success([.initial(plant)])); await wait { vm.state == .loaded }
        XCTAssertTrue(vm.noRecords); vm.abandonDeletion(); vm.disappear()
    }
    private func wait(_ condition: () -> Bool) async {
        for _ in 0..<1000 { if condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
    private func make(_ load: any LoadPlantTimelineUseCase, clock: @escaping () -> Date = Date.init,
                      zone: @escaping () -> TimeZone = { TimeZone(identifier: "Etc/UTC")! }) -> PlantTimelineViewModel {
        let id = StorageTestFixture.plant(1).id
        return PlantTimelineViewModel(plantID: id, load: load,
            photos: PlantTimelinePhotoViewModel(plantID: id, read: { _, _ in XCTFail("Metadata must not eagerly read JPEG"); return Data() }),
            clock: clock, zone: zone, sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
    }
    func testEmptyNotFoundFailureRefreshHidesStaleAndRetryReentryReadAgain() async {
        let load = TimelineLoadGate(), vm = make(load), plant = StorageTestFixture.plant(1)
        XCTAssertEqual(vm.state, .idle)
        vm.appear(); vm.appear(); vm.foreground(); await load.waitCount(1)
        XCTAssertEqual(vm.state, .loading)
        await load.finish(0, .success([.initial(plant)])); await wait { vm.state == .loaded }
        XCTAssertTrue(vm.noRecords); XCTAssertTrue(vm.noCare); XCTAssertTrue(vm.originIsLast)
        vm.foreground(); await load.waitCount(2)
        XCTAssertEqual(vm.groups, []); XCTAssertEqual(vm.entries, [])
        await load.finish(1, .failure(PlantStorageError.storage)); await wait { vm.state == .failed }
        XCTAssertFalse(vm.noRecords)
        vm.refresh(); await load.waitCount(3)
        await load.finish(2, .success(nil)); await wait { vm.state == .notFound }
        vm.disappear(); vm.appear(); await load.waitCount(4)
        await load.finish(3, .success([.initial(plant)])); await wait { vm.state == .loaded }
        vm.disappear()
    }
    func testLateMetadataCannotPublishAfterDisappearOrReplacementSession() async {
        let load = TimelineLoadGate(), vm = make(load), plant = StorageTestFixture.plant(1)
        vm.appear(); await load.waitCount(1); vm.disappear(); vm.appear(); await load.waitCount(2)
        await load.finish(0, .success([.initial(plant)])); await Task.yield()
        XCTAssertEqual(vm.state, .loading); XCTAssertTrue(vm.groups.isEmpty)
        await load.finish(1, .failure(PlantStorageError.storage)); await wait { vm.state == .failed }
        vm.refresh(); await load.waitCount(3); vm.disappear()
        await load.finish(2, .failure(PlantStorageError.storage)); await Task.yield()
        XCTAssertEqual(vm.state, .idle); XCTAssertEqual(vm.photos.cachedCount, 0)
    }
    func testContextReordersFooterWithoutReadsAndDoesNotLoseOriginalDates() async {
        let load = TimelineLoadGate()
        let iso = ISO8601DateFormatter()
        let initialDate = iso.date(from: "2026-10-12T00:30:00Z")!, eventDate = iso.date(from: "2026-10-11T23:00:00Z")!
        let original = StorageTestFixture.plant(1)
        let plant = Plant(id: original.id, name: original.name, confirmedSpecies: original.confirmedSpecies,
                          createdAt: initialDate, location: nil, careSheet: original.careSheet)
        let event = CareEvent(id: UUID(), plantID: plant.id, kind: .other, occurredAt: eventDate,
                             note: nil, createdAt: initialDate.addingTimeInterval(1), timeZoneIdentifier: "Europe/London")
        var zone = TimeZone(identifier: "Etc/UTC")!, now = initialDate.addingTimeInterval(10000)
        let vm = make(load, clock: { now }, zone: { zone })
        vm.appear(); await load.waitCount(1)
        await load.finish(0, .success([.care(event), .initial(plant)])); await wait { vm.state == .loaded }
        XCTAssertFalse(vm.originIsLast); XCTAssertEqual(vm.groups.count, 2)
        zone = TimeZone(identifier: "Europe/Madrid")!; vm.updateContext()
        XCTAssertTrue(vm.originIsLast); XCTAssertEqual(vm.groups.count, 1)
        XCTAssertEqual(vm.groups[0].entries, [.care(event), .initial(plant)])
        now = now.addingTimeInterval(-172800); vm.updateContext()
        XCTAssertEqual(vm.entries, [.care(event), .initial(plant)])
        let count = await load.count; XCTAssertEqual(count, 1)
        vm.disappear()
    }

    func testMidnightBoundaryReformatsWithoutReadAndStopsOnDisappear() async {
        let load = TimelineLoadGate(), sleep = TimelineSleepGate(), plant = StorageTestFixture.plant(1)
        var now = Date(timeIntervalSince1970: 86000)
        let vm = PlantTimelineViewModel(plantID: plant.id, load: load,
            photos: PlantTimelinePhotoViewModel(plantID: plant.id, read: { _, _ in XCTFail("No eager bytes"); return Data() }),
            clock: { now }, zone: { TimeZone(identifier: "Etc/UTC")! }, sleep: { try await sleep.wait($0) })
        vm.appear(); await load.waitCount(1); await sleep.waitCount(1)
        await load.finish(0, .success([.initial(plant)])); await wait { vm.state == .loaded }
        await sleep.waitCount(2)
        XCTAssertEqual(vm.groups[0].title, "Hoy")
        now = Date(timeIntervalSince1970: 86401)
        await sleep.finish(1); await wait { vm.groups.first?.title == "Ayer" }
        let count = await load.count, delay = await sleep.delays[1]
        XCTAssertEqual(count, 1); XCTAssertEqual(delay, 400, accuracy: 0.01)
        vm.disappear(); await sleep.finishAll(); await Task.yield(); XCTAssertTrue(vm.groups.isEmpty)
    }
}

private actor TimelineDeletionGate: DeleteCareEventUseCase {
    var expected: [CareEvent] = []
    private var pending: [CheckedContinuation<CareEvent, Error>] = []
    var count: Int { pending.count }
    func execute(_ expected: CareEvent) async throws -> CareEvent {
        self.expected.append(expected)
        return try await withCheckedThrowingContinuation { pending.append($0) }
    }
    func finish(_ index: Int, _ result: Result<CareEvent, Error>) { pending[index].resume(with: result) }
    func waitCount(_ count: Int) async {
        for _ in 0..<1000 { if pending.count >= count { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
}

private struct FailingTimelinePhotoDeletion: DeletePlantPhotoUseCase {
    func execute(_ identity: PlantPhotoIdentity, expected: PlantPhoto) async throws -> PlantPhoto { throw PlantPhotoError.storage }
}

private actor TimelineSleepGate {
    var delays: [TimeInterval] = []
    private var continuations: [Int: CheckedContinuation<Void, Error>] = [:]
    func wait(_ seconds: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuations[delays.count] = continuation; delays.append(seconds)
        }
    }
    func finish(_ index: Int) { continuations.removeValue(forKey: index)?.resume() }
    func finishAll() { continuations.values.forEach { $0.resume(throwing: CancellationError()) }; continuations = [:] }
    func waitCount(_ count: Int) async {
        for _ in 0..<1000 { if delays.count >= count { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
}

actor TimelineLoadGate: LoadPlantTimelineUseCase {
    private var continuations: [CheckedContinuation<[PlantTimelineEntry]?, Error>] = []
    var count: Int { continuations.count }
    func execute(for plantID: UUID) async throws -> [PlantTimelineEntry]? {
        try await withCheckedThrowingContinuation { continuations.append($0) }
    }
    func finish(_ index: Int, _ result: Result<[PlantTimelineEntry]?, Error>) { continuations[index].resume(with: result) }
    func waitCount(_ count: Int) async {
        for _ in 0..<1000 { if continuations.count >= count { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
    }
}
