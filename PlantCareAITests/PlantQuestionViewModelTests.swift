import XCTest
@testable import PlantCareAI

actor SuspendedQuestionPreparation: AskPlantQuestionUseCase {
    var pending: CheckedContinuation<Void, Never>?
    func prepare(plantID: UUID, question: String, queriedAt: Date, timeZone: TimeZone) async throws -> PreparedPlantQuestion {
        await withCheckedContinuation { pending = $0 }
        return .init(requestID: UUID(), plant: BuildPlantAnalysisContextTests.plant(), context: try BuildPlantQuestionContextTests().build(question: question))
    }
    func execute(_ prepared: PreparedPlantQuestion) async throws -> PlantQuestionResult { throw PlantQuestionError.invalidResponse }
    func release() { pending?.resume(); pending = nil }
}

@MainActor
final class PlantQuestionViewModelTests: XCTestCase {
    func testDetailLoadedGuardMissingJPEGSnapshotsAndTerminalClose() async throws {
        let local = QuestionLocalSpy(), provider = QuestionProviderSpy(), consent = ConsentDouble()
        let detail = PlantDetailViewModel(id: BuildPlantAnalysisContextTests.plantID, loadDetail: .init(repository: local),
            loadPhoto: .init(repository: local), update: .init(repository: local))
        var factories = 0
        detail.makeQuestion = { plant, image in
            factories += 1; XCTAssertNil(image)
            return .init(plant: plant, image: image, ask: AskPlantQuestionTests().use(local, provider),
                authorize: .init(repository: consent, scope: self.scope), destination: nil, configurationIsCurrent: { true })
        }
        XCTAssertNil(detail.questionEditor()); XCTAssertEqual(factories, 0)
        await detail.load()
        guard case .failed = detail.photoState else { return XCTFail("Missing JPEG must not block metadata") }
        let modal = try XCTUnwrap(detail.questionEditor()); XCTAssertEqual(modal.plant?.name, "NO ENVIAR NOMBRE")
        XCTAssertEqual(modal.question, ""); XCTAssertNil(modal.result)
        detail.hasPresentedEditor = true; XCTAssertNil(detail.questionEditor())
        detail.hasPresentedEditor = false; XCTAssertNil(detail.questionEditor())
        detail.invalidateDeletedPlant(); XCTAssertTrue(modal.closed); XCTAssertNil(detail.questionEditor())
        let requests = await provider.contexts; XCTAssertTrue(requests.isEmpty)
    }
    func testCancelledPreparationAndConsentPreferenceContinuationsNeverReopenNotice() async throws {
        let suspended = SuspendedQuestionPreparation(), consent = ConsentDouble()
        let first = PlantQuestionViewModel(plant: BuildPlantAnalysisContextTests.plant(), image: nil, ask: suspended,
            authorize: .init(repository: consent, scope: scope), destination: nil, configurationIsCurrent: { true })
        first.question = "texto"; first.send()
        for _ in 0..<1000 { if await suspended.pending != nil { break }; try await Task.sleep(for: .milliseconds(2)) }
        first.cancelRequest(); await suspended.release(); try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(first.state, .idle); XCTAssertFalse(first.showingConsent); XCTAssertEqual(first.question, "texto")
        let provider = QuestionProviderSpy(); await consent.configure(pauseRead: true)
        let second = model(provider: provider, consent: consent); second.question = "otra"; second.send()
        for _ in 0..<1000 { if await consent.isWaiting { break }; try await Task.sleep(for: .milliseconds(2)) }
        second.close(); await consent.resume(); try await Task.sleep(for: .milliseconds(30))
        XCTAssertTrue(second.closed); XCTAssertFalse(second.showingConsent); XCTAssertNil(second.result)
        let calls = await provider.contexts; XCTAssertTrue(calls.isEmpty)
    }
    func testPreferenceFailuresNoHTTPAndNewSendRereadsChangedPlant() async throws {
        let local = QuestionLocalSpy(), provider = QuestionProviderSpy(), consent = ConsentDouble()
        await consent.configure(failRead: true)
        let vm = model(local: local, provider: provider, consent: consent); vm.question = "primera"; vm.send(); await wait { vm.state == .failed }
        var calls = await provider.contexts; XCTAssertTrue(calls.isEmpty)
        await consent.configure(failWrite: true); vm.send(); await wait { vm.state == .awaitingConsent }; vm.acceptConsent(); await wait { vm.state == .failed }
        calls = await provider.contexts; XCTAssertTrue(calls.isEmpty)
        await consent.configure(value: scope); vm.send(); await wait { vm.state == .answered }
        await local.configure(plants: [BuildPlantAnalysisContextTests.plant(location: "Ubicación nueva")])
        vm.question = "segunda"; vm.send(); await wait { vm.state == .answered }
        calls = await provider.contexts; XCTAssertEqual(calls.map(\.currentUserLocation), ["Interior", "Ubicación nueva"])
        XCTAssertEqual(calls.map(\.question), ["primera", "segunda"])
    }
    let scope = ExternalAIConsent(recipient: "question-test", noticeVersion: 5)
    func model(local: QuestionLocalSpy = .init(), provider: QuestionProviderSpy, consent: ConsentDouble, current: @escaping () -> Bool = { true }) -> PlantQuestionViewModel {
        .init(plant: BuildPlantAnalysisContextTests.plant(), image: nil, ask: AskPlantQuestionTests().use(local, provider),
            authorize: .init(repository: consent, scope: scope), destination: nil, configurationIsCurrent: current)
    }
    func wait(_ condition: @escaping () -> Bool) async {
        for _ in 0..<1000 { if condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTAssertTrue(condition())
    }
    func testExistingAcceptanceSuccessEditWithoutSendAndReplacementIndependent() async throws {
        let provider = QuestionProviderSpy(), consent = ConsentDouble(); await consent.configure(value: scope)
        let vm = model(provider: provider, consent: consent)
        XCTAssertFalse(vm.canSend); vm.question = "primera"; vm.send(); vm.send(); await wait { vm.state == .answered }
        XCTAssertFalse(vm.showingConsent); XCTAssertTrue(vm.canSend)
        vm.question = "segunda"; XCTAssertEqual(vm.result?.question, "primera")
        let before = await provider.contexts; XCTAssertEqual(before.count, 1)
        vm.send(); XCTAssertNil(vm.result); await wait { vm.state == .answered }
        XCTAssertEqual(vm.result?.question, "segunda"); let contexts = await provider.contexts
        XCTAssertEqual(contexts.map(\.question), ["primera", "segunda"])
        vm.close(); XCTAssertNil(vm.result); XCTAssertEqual(vm.question, ""); XCTAssertNil(vm.plant)
    }
    func testUnacceptedRejectNoHTTPAndAcceptanceNoAdditionalNotice() async throws {
        let provider = QuestionProviderSpy(), consent = ConsentDouble(), vm = model(provider: provider, consent: consent)
        vm.question = "texto"; vm.send(); await wait { vm.state == .awaitingConsent }
        XCTAssertTrue(vm.showingConsent); vm.cancelConsent(); XCTAssertEqual(vm.question, "texto")
        let calls = await provider.contexts; XCTAssertTrue(calls.isEmpty)
        vm.send(); await wait { vm.state == .awaitingConsent }; vm.acceptConsent(); await wait { vm.state == .answered }
        vm.send(); await wait { vm.state == .answered }; XCTAssertFalse(vm.showingConsent)
    }
    func testCancelNoncooperativeCompletionAndCloseNoResurrection() async throws {
        let provider = QuestionProviderSpy(), consent = ConsentDouble(); await consent.configure(value: scope); await provider.configure(hold: true)
        let vm = model(provider: provider, consent: consent); vm.question = "texto"; vm.send()
        for _ in 0..<1000 { if await provider.continuation != nil { break }; try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertTrue(vm.busy); vm.cancelRequest(); XCTAssertEqual(vm.question, "texto"); XCTAssertEqual(vm.state, .idle)
        await provider.release(); try await Task.sleep(for: .milliseconds(30)); XCTAssertNil(vm.result)
        vm.close(); vm.send(); XCTAssertTrue(vm.closed); XCTAssertNil(vm.result)
    }
    func testErrorExplicitRetryAndConfigurationChangedPreventsPublication() async throws {
        let provider = QuestionProviderSpy(), consent = ConsentDouble(); await consent.configure(value: scope); await provider.configure(failure: .network)
        var current = true
        let vm = model(provider: provider, consent: consent, current: { current }); vm.question = "texto"; vm.send(); await wait { vm.state == .failed }
        XCTAssertEqual(vm.errorKey, "question.error.network"); XCTAssertEqual(vm.question, "texto")
        await provider.configure(hold: true); vm.send()
        for _ in 0..<1000 { if await provider.continuation != nil { break }; try await Task.sleep(for: .milliseconds(2)) }
        current = false; await provider.release(); await wait { vm.state == .failed }
        XCTAssertEqual(vm.errorKey, "question.error.configuration"); XCTAssertNil(vm.result)
    }
}
