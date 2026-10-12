import XCTest
@testable import PlantCareAI

@MainActor
final class QuickWateringViewModelTests: XCTestCase {
    func testPickerRangeIncludesSelectedInstantAcrossEastwardZoneAndClockRegression() {
        let repository = SuspendedWateringRepository()
        var clock = ISO8601DateFormatter().date(from: "2026-01-12T12:00:00Z")!
        var zone = TimeZone(identifier: "America/Los_Angeles")!
        let vm = QuickWateringViewModel(plant: StorageTestFixture.plant(1), register: RegisterWatering(repository: repository),
            now: { clock }, zone: { zone }, onSaved: { _ in XCTFail() })
        let selected = vm.occurredAt
        zone = TimeZone(identifier: "Europe/Madrid")!
        vm.refreshDisplayZone()
        XCTAssertLessThan(vm.today, selected) // A start-of-day absolute picker bound would wrongly exclude today's selection.
        XCTAssertGreaterThanOrEqual(vm.latestSelectableDate, selected)
        clock = selected.addingTimeInterval(-1)
        XCTAssertEqual(vm.latestSelectableDate, selected)
        XCTAssertEqual(vm.occurredAt, selected)
    }
    func testInvalidDateDoesNotDispatchAndRepresentationCanChangeDayWithoutEditing() async throws {
        let repository = SuspendedWateringRepository()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var zone = TimeZone(identifier: "Europe/Madrid")!
        let vm = QuickWateringViewModel(plant: StorageTestFixture.plant(1), register: RegisterWatering(repository: repository), now: { now }, zone: { zone }, onSaved: { _ in XCTFail() })
        let absolute = vm.occurredAt
        let originalDay = vm.calendar.component(.day, from: absolute)
        zone = TimeZone(identifier: "America/Los_Angeles")!
        vm.refreshDisplayZone()
        XCTAssertEqual(vm.occurredAt, absolute)
        XCTAssertGreaterThanOrEqual(vm.latestSelectableDate, absolute)
        XCTAssertNotEqual(vm.calendar.component(.day, from: absolute), originalDay)
        vm.selectDate(Date(timeIntervalSince1970: .nan)); await vm.save()
        XCTAssertEqual(vm.state, .error(.validation))
        let events = await repository.events; XCTAssertEqual(events, [])
    }
    func testBusyDoubleTapSnapshotRetryAndLateCancellationCallbackOnce() async throws {
        let repository = SuspendedWateringRepository()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var clock = now
        var zone = TimeZone(identifier: "Europe/Madrid")!
        var callbacks: [CareEvent] = []
        let vm = QuickWateringViewModel(plant: StorageTestFixture.plant(1), register: RegisterWatering(repository: repository),
            now: { clock }, zone: { zone }, onSaved: { callbacks.append($0) })
        vm.setNote(" \nAgua\n🌿 \n")
        let first = Task { await vm.save() }
        await repository.waitForDispatch()
        XCTAssertTrue(vm.isSaving)
        vm.setNote("blocked"); vm.selectDay(offset: -1)
        await vm.save()
        let original = await repository.events[0]
        await repository.finish(.failure(CareEventError.storage)); await first.value
        XCTAssertEqual(vm.state, .error(.storage)); XCTAssertEqual(callbacks, [])
        clock = clock.addingTimeInterval(86400)
        zone = TimeZone(identifier: "America/Los_Angeles")!
        let before = vm.dateDescription
        vm.refreshDisplayZone()
        XCTAssertNotEqual(vm.dateDescription, before)
        let retry = Task { await vm.save() }
        await repository.waitForDispatch()
        let retried = await repository.events[1]
        XCTAssertEqual(retried, original) // All seven fields, including origin zone and first dispatch time.
        retry.cancel()
        await repository.finish(.success(retried)); await retry.value
        XCTAssertEqual(vm.state, .saved); XCTAssertEqual(callbacks, [original])
        await vm.save(); XCTAssertEqual(callbacks.count, 1)
    }

    func testEditingAfterErrorNewIntentionAndSelectionCapturesCurrentZone() async {
        let repository = SuspendedWateringRepository()
        var zone = TimeZone(identifier: "Europe/Madrid")!
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let vm = QuickWateringViewModel(plant: StorageTestFixture.plant(1), register: RegisterWatering(repository: repository), now: { now }, zone: { zone }, onSaved: { _ in })
        let first = Task { await vm.save() }; await repository.waitForDispatch()
        let original = await repository.events[0]
        await repository.finish(.failure(CareEventError.storage)); await first.value
        zone = TimeZone(identifier: "America/Los_Angeles")!
        vm.selectDay(offset: -1); vm.setNote(" ")
        let second = Task { await vm.save() }; await repository.waitForDispatch()
        let edited = await repository.events[1]
        XCTAssertNotEqual(original.id, edited.id)
        XCTAssertEqual(edited.timeZoneIdentifier, zone.identifier); XCTAssertNil(edited.note)
        XCTAssertEqual(edited.occurredAt, vm.yesterday)
        await repository.finish(.success(edited)); await second.value
        let fresh = QuickWateringViewModel(plant: vm.plant, register: RegisterWatering(repository: repository), now: { now }, zone: { zone }, onSaved: { _ in })
        XCTAssertNotEqual(fresh.id, vm.id); XCTAssertEqual(fresh.note, ""); XCTAssertEqual(fresh.occurredAt, fresh.today)
    }
}

private actor SuspendedWateringRepository: CareEventRepository {
    var events: [CareEvent] = []
    private var continuation: CheckedContinuation<CareEvent, Error>?
    private var dispatched: CheckedContinuation<Void, Never>?
    func saveCareEvent(_ event: CareEvent) async throws -> CareEvent {
        events.append(event)
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            dispatched?.resume(); dispatched = nil
        }
    }
    func waitForDispatch() async {
        if continuation != nil { return }
        await withCheckedContinuation { dispatched = $0 }
    }
    func finish(_ result: Result<CareEvent, Error>) { continuation?.resume(with: result); continuation = nil }
    func loadCareEvents(for plantID: UUID) async throws -> [CareEvent] { [] }
}
