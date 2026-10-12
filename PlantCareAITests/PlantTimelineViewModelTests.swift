import XCTest
@testable import PlantCareAI

@MainActor
final class PlantTimelineViewModelTests: XCTestCase {
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
