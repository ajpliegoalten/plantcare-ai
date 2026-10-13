import XCTest
@testable import PlantCareAI

@MainActor
final class LastWateringHintViewModelTests: XCTestCase {
    private func wait(_ condition: () async -> Bool) async {
        for _ in 0..<1000 { if await condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTFail("Condition not reached")
    }

    func testPlantDeletionPurgesLoadedAndInFlightAndPreventsRetainedObserverReload() async {
        let loader = SuspendedWatering(), vm = LastWateringHintViewModel(plantID: UUID(), load: loader)
        vm.appear(); await wait { await loader.count == 1 }
        vm.invalidateDeletedPlant()
        await loader.resolve(0, .success(Date())); await Task.yield()
        vm.appear(); vm.foreground(); vm.invalidate(); vm.updateContext()
        XCTAssertEqual(vm.state, .idle); XCTAssertNil(vm.value(compact: true))
        let count = await loader.count; XCTAssertEqual(count, 1)
        let loaded = LastWateringHintViewModel(plantID: UUID(), load: loader)
        loaded.appear(); await wait { await loader.count == 2 }
        await loader.resolve(1, .success(nil)); await wait { loaded.state == .loaded(nil) }
        loaded.invalidateDeletedPlant(); XCTAssertEqual(loaded.state, .idle)
    }

    func testIdleDeduplicationFailureNoLoopAndForegroundRecoveryThenCache() async {
        let loader = SuspendedWatering(), vm = LastWateringHintViewModel(plantID: UUID(), load: loader)
        XCTAssertEqual(vm.state, .idle); XCTAssertNil(vm.value(compact: true))
        vm.appear(); vm.appear(); vm.foreground()
        await wait { await loader.count == 1 }
        XCTAssertEqual(vm.state, .loading); XCTAssertNil(vm.value(compact: true))
        await loader.resolve(0, .failure(CareEventError.storage))
        await wait { vm.state == .failed }
        vm.updateContext(); await Task.yield()
        let count = await loader.count; XCTAssertEqual(count, 1)
        XCTAssertNil(vm.value(compact: false))
        vm.foreground(); await wait { await loader.count == 2 }
        await loader.resolve(1, .success(nil)); await wait { vm.state == .loaded(nil) }
        XCTAssertEqual(vm.value(compact: true), "Sin riegos registrados")
        vm.disappear(); vm.appear(); vm.foreground(); vm.updateContext(); await Task.yield()
        let cachedCount = await loader.count; XCTAssertEqual(cachedCount, 2)
        vm.disappear()
    }

    func testInvalidationAndDisappearanceRejectLateSuccessAndFailure() async {
        let loader = SuspendedWatering(), id = UUID()
        let vm = LastWateringHintViewModel(plantID: id, load: loader)
        vm.appear(); await wait { await loader.count == 1 }
        vm.invalidate(); await wait { await loader.count == 2 }
        let latest = Date(timeIntervalSince1970: 800)
        await loader.resolve(1, .success(latest)); await wait { vm.state == .loaded(latest) }
        await loader.resolve(0, .success(Date(timeIntervalSince1970: 1))); await Task.yield()
        XCTAssertEqual(vm.state, .loaded(latest))
        vm.invalidate(); await wait { await loader.count == 3 }
        vm.disappear(); XCTAssertEqual(vm.state, .idle)
        vm.appear(); await wait { await loader.count == 4 }
        await loader.resolve(3, .failure(CareEventError.storage)); await wait { vm.state == .failed }
        await loader.resolve(2, .success(nil)); await Task.yield()
        XCTAssertEqual(vm.state, .failed)
        vm.disappear(); vm.invalidate()
        let count = await loader.count; XCTAssertEqual(count, 4)
        vm.appear(); await wait { await loader.count == 5 }
        await loader.resolve(4, .success(latest)); await wait { vm.state == .loaded(latest) }
        let ids = await loader.ids; XCTAssertEqual(ids, Array(repeating: id, count: 5))
        vm.disappear()
    }

    func testTechnicalCancellationReturnsIdleNotAbsenceAndIsReloadable() async {
        let loader = SuspendedWatering(), vm = LastWateringHintViewModel(plantID: UUID(), load: loader)
        vm.appear(); await wait { await loader.count == 1 }
        await loader.resolve(0, .failure(CancellationError())); await wait { vm.state == .idle }
        XCTAssertNil(vm.value(compact: true))
        vm.disappear(); vm.appear(); await wait { await loader.count == 2 }
        await loader.resolve(1, .success(nil)); await wait { vm.state == .loaded(nil) }; vm.disappear()
    }

    func testDayBoundaryZoneAndClockOnlyReformatDoNotReadOrWrite() async {
        let loader = SuspendedWatering(), scheduler = WateringBoundary()
        var now = ISO8601DateFormatter().date(from: "2026-10-12T23:30:00Z")!
        var zone = TimeZone(secondsFromGMT: 0)!
        let vm = LastWateringHintViewModel(plantID: UUID(), load: loader, clock: { now }, zone: { zone }, sleep: { try await scheduler.sleep($0) })
        vm.appear(); await wait { let reads = await loader.count; let boundaries = await scheduler.count; return reads == 1 && boundaries > 0 }
        let event = now
        await loader.resolve(0, .success(event)); await wait { vm.state == .loaded(event) }
        XCTAssertEqual(vm.value(compact: true), "Último riego: hoy")
        now = now.addingTimeInterval(3600)
        await scheduler.fireLatest(); await wait { vm.now == now }
        XCTAssertEqual(vm.value(compact: true), "Último riego: 12 oct 2026")
        zone = TimeZone(identifier: "America/Los_Angeles")!; vm.updateContext()
        XCTAssertEqual(vm.value(compact: true), "Último riego: hoy")
        now = now.addingTimeInterval(-172800); vm.foreground()
        XCTAssertEqual(vm.value(compact: true), "Último riego: 12 oct 2026")
        let count = await loader.count; XCTAssertEqual(count, 1)
        vm.disappear(); await scheduler.cancelAll()
    }
}

private actor SuspendedWatering: LoadLastWateringUseCase {
    var ids: [UUID] = []
    var count: Int { ids.count }
    var pending: [Int: CheckedContinuation<Date?, Error>] = [:]
    func execute(for plantID: UUID) async throws -> Date? {
        let index = ids.count; ids.append(plantID)
        return try await withCheckedThrowingContinuation { pending[index] = $0 }
    }
    func resolve(_ index: Int, _ result: Result<Date?, Error>) { pending.removeValue(forKey: index)?.resume(with: result) }
}

private actor WateringBoundary {
    var count = 0
    var pending: [Int: CheckedContinuation<Void, Error>] = [:]
    func sleep(_ seconds: TimeInterval) async throws {
        XCTAssertGreaterThan(seconds, 0)
        count += 1; let index = count
        try await withCheckedThrowingContinuation { pending[index] = $0 }
    }
    func fireLatest() { pending.removeValue(forKey: count)?.resume() }
    func cancelAll() { for continuation in pending.values { continuation.resume(throwing: CancellationError()) }; pending = [:] }
}
