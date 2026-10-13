import XCTest
@testable import PlantCareAI

@MainActor
final class PlantPhotoAnalysisViewModelTests: XCTestCase {
    private func savingModel(_ store: AcceptanceSpy, provider: AnalysisProviderSpy,
                             onSaved: @escaping @MainActor (SavedPlantPhotoAnalysis) -> Void = { _ in }) async -> PlantPhotoAnalysisViewModel {
        let local = AnalysisLocalSpy(), consent = ConsentDouble()
        await consent.configure(value: scope)
        return PlantPhotoAnalysisViewModel(plantID: BuildPlantAnalysisContextTests.plantID,
            identity: .initial(BuildPlantAnalysisContextTests.plantID), analyze: AnalyzePlantPhotoTests().useCase(local, provider),
            authorize: .init(repository: consent, scope: scope), destination: nil,
            queriedAt: BuildPlantAnalysisContextTests.date(300), keep: store, onSaved: onSaved, configurationIsCurrent: { true })
    }

    func testLocalSaveRetryKeepsLiteralSnapshotResultNoExtraHTTPAndCallbackOnce() async throws {
        let store = AcceptanceSpy(), provider = AnalysisProviderSpy()
        await store.configure(failure: .storage)
        var records: [SavedPlantPhotoAnalysis] = []
        let vm = await savingModel(store, provider: provider) { records.append($0) }
        vm.start(); await wait { vm.state == .result }; XCTAssertTrue(vm.canSave)
        let result = vm.result; vm.save(); vm.save(); await wait { vm.saveState == .failed }
        XCTAssertEqual(vm.result, result); XCTAssertFalse(vm.saveNeedsNewIntent); XCTAssertTrue(records.isEmpty)
        await store.configure(); vm.save(); vm.save(); await wait { vm.saveState == .saved }
        let snapshots = await store.snapshots
        XCTAssertEqual(snapshots.count, 2); XCTAssertEqual(snapshots[0], snapshots[1])
        XCTAssertEqual(records, [snapshots[0].record])
        let calls = await provider.calls; XCTAssertEqual(calls.count, 1)
        vm.save(); XCTAssertEqual(records.count, 1); vm.close()
    }

    func testCommitBlocksCloseDoubleDispatchAndRecognizesResultAfterSuspension() async throws {
        let store = AcceptanceSpy(), provider = AnalysisProviderSpy()
        await store.configure(hold: true); var callbacks = 0
        let vm = await savingModel(store, provider: provider) { _ in callbacks += 1 }
        vm.start(); await wait { vm.state == .result }; vm.save(); vm.save()
        XCTAssertEqual(vm.saveState, .saving); XCTAssertFalse(vm.close()); XCTAssertFalse(vm.closed)
        for _ in 0..<1000 { if await store.continuation != nil { break }; await Task.yield() }
        await store.release(); await wait { vm.saveState == .saved }
        let snapshots = await store.snapshots; XCTAssertEqual(snapshots.count, 1); XCTAssertEqual(callbacks, 1)
        XCTAssertTrue(vm.close())
    }

    func testConflictRequiresNewIntentAndClosingStorageFailureAbandonsRetry() async throws {
        for failure in [KeepPlantPhotoAnalysisError.conflict, .notFound, .readFailure, .storage] {
            let store = AcceptanceSpy(), provider = AnalysisProviderSpy(); await store.configure(failure: failure)
            let vm = await savingModel(store, provider: provider)
            vm.start(); await wait { vm.state == .result }; vm.save(); await wait { vm.saveState == .failed }
            XCTAssertEqual(vm.saveNeedsNewIntent, failure != .storage)
            if failure != .storage { vm.save(); let snapshots = await store.snapshots; XCTAssertEqual(snapshots.count, 1) }
            XCTAssertTrue(vm.close()); vm.save(); XCTAssertNil(vm.result)
            let snapshots = await store.snapshots; XCTAssertEqual(snapshots.count, 1)
        }
    }
    private let scope = ExternalAIConsent(recipient: "synthetic-analysis", noticeVersion: 5)
    private func make(local: AnalysisLocalSpy, provider: AnalysisProviderSpy, consent: ConsentDouble, current: @escaping () -> Bool = { true }) -> PlantPhotoAnalysisViewModel {
        let use = AnalyzePlantPhotoTests().useCase(local, provider)
        return PlantPhotoAnalysisViewModel(plantID: BuildPlantAnalysisContextTests.plantID, identity: .initial(BuildPlantAnalysisContextTests.plantID),
            analyze: use, authorize: .init(repository: consent, scope: scope), destination: .init(destination: "https://synthetic.invalid/v1", model: "test"),
            queriedAt: BuildPlantAnalysisContextTests.date(300), timeZone: TimeZone(identifier: "Africa/Abidjan")!, configurationIsCurrent: current)
    }
    private func wait(_ condition: @escaping () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<500 { if condition() { return }; try? await Task.sleep(for: .milliseconds(10)) }
        XCTFail("state timeout", file: file, line: line)
    }
    func testConsentRejectZeroAndExplicitRetryAcceptOneDuplicateTapIgnored() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        let vm = make(local: local, provider: provider, consent: consent)
        vm.start(); vm.start(); await wait { vm.state == .awaitingConsent }
        XCTAssertNotNil(vm.image); XCTAssertNotNil(vm.plant)
        vm.cancelConsent(); let none = await provider.calls; XCTAssertTrue(none.isEmpty)
        XCTAssertEqual(vm.state, .failed)
        vm.retry(); vm.retry(); await wait { vm.state == .awaitingConsent }
        vm.acceptConsent(); vm.acceptConsent(); await wait { vm.state == .result }
        let calls = await provider.calls, writes = await consent.writes
        XCTAssertEqual(calls.count, 1); XCTAssertEqual(writes, 1); XCTAssertEqual(vm.result?.identity, vm.identity)
        let result = vm.result; vm.close(); XCTAssertNil(vm.result); XCTAssertNil(vm.image); XCTAssertNil(vm.plant)
        XCTAssertNotNil(result)
    }
    func testOldV4DoesNotAuthorizeContextV5RememberedScopeSkipsSecondNotice() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        await consent.configure(value: .init(recipient: scope.recipient, noticeVersion: 4))
        let first = make(local: local, provider: provider, consent: consent)
        first.start(); await wait { first.state == .awaitingConsent }; first.acceptConsent(); await wait { first.state == .result }
        first.close()
        let second = make(local: local, provider: provider, consent: consent)
        XCTAssertNil(second.result); second.start(); await wait { second.state == .result }
        let calls = await provider.calls; XCTAssertEqual(calls.count, 2); XCTAssertFalse(second.showingConsent)
        second.close()
    }
    func testConsentReadAndRecordFailuresFailClosed() async throws {
        for writing in [false, true] {
            let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
            await consent.configure(failRead: !writing, failWrite: writing)
            let vm = make(local: local, provider: provider, consent: consent)
            vm.start(); await wait { vm.state == (writing ? .awaitingConsent : .failed) }
            if writing { vm.acceptConsent(); await wait { vm.state == .failed } }
            let calls = await provider.calls; XCTAssertTrue(calls.isEmpty); XCTAssertNil(vm.result); vm.close()
        }
    }
    func testConfigurationDriftAtAcceptNeverRecordsOrSendsAndMissingConfigFails() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        var current = true
        let vm = make(local: local, provider: provider, consent: consent, current: { current })
        vm.start(); await wait { vm.state == .awaitingConsent }; current = false; vm.acceptConsent(); await wait { vm.state == .failed }
        let calls = await provider.calls, writes = await consent.writes
        XCTAssertTrue(calls.isEmpty); XCTAssertEqual(writes, 0); XCTAssertEqual(vm.errorKey, "analysis.error.configuration"); vm.close()
        let missing = PlantPhotoAnalysisViewModel(plantID: UUID(), identity: .initial(UUID()), analyze: nil,
            authorize: .init(repository: consent, scope: scope), destination: nil, configurationIsCurrent: { true })
        missing.start(); await wait { missing.state == .failed }; XCTAssertEqual(missing.errorKey, "analysis.error.configuration"); missing.close()
    }
    func testCloseDuringProviderIgnoresLateResultReleasesBytesAndModalGateAllowsReopen() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        await consent.configure(value: scope); await provider.setHold()
        let gate = PlantPhotoAnalysisPresentationGate()
        let vm = try XCTUnwrap(gate.open { make(local: local, provider: provider, consent: consent) })
        XCTAssertNil(gate.open { make(local: local, provider: provider, consent: consent) })
        vm.start(); await wait { vm.state == .analyzing && vm.image != nil }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; await Task.yield() }
        vm.close(); await provider.release()
        await Task.yield(); XCTAssertNil(vm.result); XCTAssertNil(vm.image)
        let next = try XCTUnwrap(gate.open { make(local: local, provider: provider, consent: consent) })
        next.start(); await wait { next.state == .result }; XCTAssertNotNil(next.result); next.close()
    }
    func testRetryKeepsCapturedQueryAndReferenceZone() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        let vm = make(local: local, provider: provider, consent: consent)
        vm.start(); await wait { vm.state == .awaitingConsent }; vm.cancelConsent(); vm.retry()
        await wait { vm.state == .awaitingConsent }; vm.acceptConsent(); await wait { vm.state == .result }
        let calls = await provider.calls
        XCTAssertEqual(calls.first?.1.queryDate, "1970-10-28"); XCTAssertEqual(calls.first?.1.referenceTimeZone, "Africa/Abidjan")
        vm.close()
    }
    func testConfigurationDriftDuringConsentRecordStopsTransportAndDuringProviderStopsPublication() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        await consent.configure(pauseWrite: true); var current = true
        let vm = make(local: local, provider: provider, consent: consent, current: { current })
        vm.start(); await wait { vm.state == .awaitingConsent }; vm.acceptConsent()
        for _ in 0..<1000 { if await consent.isWaiting { break }; await Task.yield() }
        let waiting = await consent.isWaiting; XCTAssertTrue(waiting)
        current = false; await consent.resume(); await wait { vm.state == .failed }
        let none = await provider.calls; XCTAssertTrue(none.isEmpty); XCTAssertNil(vm.result); vm.close()
        await consent.configure(value: scope); current = true; await provider.setHold()
        let next = make(local: local, provider: provider, consent: consent, current: { current })
        next.start(); await wait { next.state == .analyzing && next.image != nil }
        for _ in 0..<1000 { if await provider.continuation != nil { break }; await Task.yield() }
        current = false; await provider.release(); await wait { next.state == .failed }
        XCTAssertNil(next.result); XCTAssertEqual(next.errorKey, "analysis.error.configuration"); next.close()
    }
    func testTimelineProgrammaticCareModalAndDeletionGuardsWithoutSideEffects() async throws {
        let local = AnalysisLocalSpy(), provider = AnalysisProviderSpy(), consent = ConsentDouble()
        let plant = try await local.loadPlants()[0]
        let event = CareEvent(id: UUID(), plantID: plant.id, kind: .other, occurredAt: BuildPlantAnalysisContextTests.date(-1), note: nil,
            createdAt: plant.createdAt, timeZoneIdentifier: "Africa/Abidjan")
        await local.setEvents([event])
        let timeline = PlantTimelineViewModel(plantID: plant.id,
            load: LoadPlantTimeline(detail: LoadPlantDetail(repository: local), care: local, photos: local),
            photos: PlantTimelinePhotoViewModel(plantID: plant.id, loadInitial: LoadInitialPlantPhoto(repository: local), loadAdditional: LoadPlantPhoto(repository: local)),
            deleteCare: AnalysisCareDeletion())
        var openings = 0
        timeline.makeAnalysis = { _, _ in openings += 1; return self.make(local: local, provider: provider, consent: consent) }
        timeline.appear(); await wait { timeline.state == .loaded }
        timeline.requestAnalysis(.care(event)); XCTAssertEqual(openings, 0)
        timeline.requestAnalysis(.initial(plant)); timeline.requestAnalysis(.initial(plant))
        XCTAssertEqual(openings, 1); XCTAssertNotNil(timeline.analysisEditor)
        timeline.requestDeletion(.care(event)); XCTAssertEqual(timeline.deletionState, .idle)
        timeline.analysisEditor?.close(); timeline.analysisEditor = nil
        timeline.requestDeletion(.care(event)); XCTAssertEqual(timeline.deletionState, .confirming)
        timeline.requestAnalysis(.initial(plant)); XCTAssertEqual(openings, 1)
        timeline.abandonDeletion(); timeline.requestAnalysis(.initial(plant)); XCTAssertEqual(openings, 2)
        let modal = timeline.analysisEditor; timeline.disappear(); XCTAssertTrue(modal?.closed == true)
        XCTAssertNil(timeline.analysisEditor)
        let calls = await provider.calls, writes = await local.writes
        XCTAssertTrue(calls.isEmpty); XCTAssertEqual(writes, 0)
    }
}

private struct AnalysisCareDeletion: DeleteCareEventUseCase {
    func execute(_ expected: CareEvent) async throws -> CareEvent { expected }
}
