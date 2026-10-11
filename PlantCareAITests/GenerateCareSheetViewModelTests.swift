import XCTest
@testable import PlantCareAI

private struct CarePhotoPreparer: IdentificationPhotoPreparing {
    func prepare(_ data: Data) async throws -> IdentificationPhoto { IdentificationPhoto(id: UUID(), jpeg: data, width: 2, height: 1) }
}

@MainActor
final class GenerateCareSheetViewModelTests: XCTestCase {
    private func wait(_ predicate: () -> Bool) async {
        for _ in 0..<1000 {
            if predicate() { return }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("State did not settle")
    }
    private func make(_ care: CareRepositoryDouble, consent: ConsentDouble = ConsentDouble(), current: @escaping () -> Bool = { true }) async -> IdentificationPhotoViewModel {
        let result = IdentificationResult(outcome: .proposals, primary: SpeciesCandidate(commonName: "Principal", scientificName: "Primary species"), alternatives: [SpeciesCandidate(commonName: "Alternativa", scientificName: "Alternative species")], uncertainty: "Duda")
        let vm = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: CarePhotoPreparer()), camera: CheckCameraAccess(access: PhotoCameraDouble()), authorize: AuthorizeExternalAIOperation(repository: consent), generateCare: GenerateCareSheet(repository: care), configurationIsCurrent: current, identify: { _ in .completed(result) })
        vm.select { Data([1]) }; await wait { !vm.isLoading }
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation || !vm.isBusy }
        if vm.authorizationState == .awaitingConfirmation { vm.confirmAuthorization() }
        await wait { !vm.isBusy }
        return vm
    }
    private func confirm(_ vm: IdentificationPhotoViewModel, manual: Bool = false) {
        if manual {
            vm.beginManualSpecies(); let session = vm.manualDraft!.id
            vm.updateManualName("  Ficus lyrata \n", sessionID: session)
        } else { vm.selectProposal(.alternative(index: 0), resultID: vm.resultID!) }
        vm.confirmSelection()
    }

    func testAlternativeAndManualDirectOneRequestNoSelectionSideEffect() async {
        for manual in [false, true] {
            let repository = CareRepositoryDouble(), vm = await make(CareRepositoryDouble())
            vm.close()
            let draft = await make(repository)
            draft.selectProposal(.primary, resultID: draft.resultID!)
            let initial = await repository.identities; XCTAssertTrue(initial.isEmpty)
            confirm(draft, manual: manual); draft.confirmSelection(); draft.retryCare()
            await wait { draft.careState == .loaded }
            let inputs = await repository.identities
            XCTAssertEqual(inputs.count, 1); XCTAssertEqual(inputs.first, draft.confirmedIdentity)
            XCTAssertEqual(inputs.first?.manualName, manual ? "Ficus lyrata" : nil)
            if !manual { XCTAssertEqual(inputs.first?.scientificName, "Alternative species") }
            XCTAssertNotNil(draft.reviewableCareSheet); XCTAssertNil(draft.identificationError)
        }
    }

    func testConsentCancelRenewalAcceptanceAndConfigurationGuard() async {
        let repository = CareRepositoryDouble(), consent = ConsentDouble()
        var current = true
        let vm = await make(repository, consent: consent, current: { current })
        await consent.configure(value: nil)
        confirm(vm); await wait { vm.careState == .awaitingConsent }
        let photo = vm.photo, identity = vm.confirmedIdentity
        vm.cancelAuthorization()
        let cancelled = await repository.identities; XCTAssertTrue(cancelled.isEmpty)
        XCTAssertEqual(vm.careState, .cancelled); XCTAssertEqual(vm.photo, photo); XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.retryCare(); await wait { vm.careState == .awaitingConsent }
        vm.confirmAuthorization(); vm.confirmAuthorization()
        await wait { vm.careState == .loaded }
        let accepted = await repository.identities; XCTAssertEqual(accepted.count, 1)
        vm.changeConfirmedSpecies(); vm.cancelSpeciesSelection()
        XCTAssertNotNil(vm.reviewableCareSheet)
        current = false; vm.changeConfirmedSpecies(); vm.confirmSelection()
        XCTAssertEqual(vm.careError, .configuration); XCTAssertNil(vm.careSheet)
        let unchanged = await repository.identities; XCTAssertEqual(unchanged.count, 1)
    }

    func testFailureIncompleteRetryAndEditingRestoresExactSheet() async {
        let repository = CareRepositoryDouble()
        await repository.configure(error: .network)
        let vm = await make(repository); confirm(vm)
        await wait { vm.careState == .failed }
        XCTAssertEqual(vm.careError, .network); XCTAssertNil(vm.careSheet)
        let identity = vm.confirmedIdentity
        await repository.configure(sheet: CareSheet(light: "", watering: "R", humidity: "H", temperature: "T", substrate: "S", fertilizer: "A"))
        vm.retryCare(); await wait { vm.careState == .failed }
        XCTAssertEqual(vm.careError, .invalidResponse); XCTAssertNil(vm.careSheet)
        await repository.configure(sheet: CareSheet(light: "L", watering: "R", humidity: "H", temperature: "T", substrate: "S", fertilizer: "A"))
        vm.retryCare(); await wait { vm.careState == .loaded }
        let sheet = vm.careSheet
        vm.changeConfirmedSpecies(); XCTAssertNil(vm.reviewableCareSheet)
        XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.cancelSpeciesSelection(); XCTAssertEqual(vm.reviewableCareSheet, sheet)
        vm.changeConfirmedSpecies(); vm.confirmSelection() // same names, new intention
        await wait { vm.careState == .loaded }
        let inputs = await repository.identities; XCTAssertEqual(inputs.count, 4)
    }

    func testCancelCloseAndLateResponseNeverPublishOrOverwriteNewIntention() async {
        for close in [false, true] {
            let repository = CareRepositoryDouble(); await repository.configure(held: true)
            let vm = await make(repository); confirm(vm)
            await wait { vm.careState == .loading }
            let identity = vm.confirmedIdentity
            vm.changeConfirmedSpecies(); vm.select { Data([2]) }; vm.identifyPhoto()
            XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertFalse(vm.isLoading)
            if close { vm.close() } else { vm.cancelCare() }
            await repository.release()
            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertNil(vm.careSheet)
            if close { XCTAssertNil(vm.photo); XCTAssertNil(vm.confirmedIdentity) }
            else {
                XCTAssertEqual(vm.confirmedIdentity, identity)
                await repository.configure(); vm.retryCare(); await wait { vm.careState == .loaded }
                XCTAssertNotNil(vm.careSheet)
            }
        }
    }

    func testManualEditingCancelPhotoFailureAndInvalidation() async {
        let repository = CareRepositoryDouble(), vm = await make(CareRepositoryDouble())
        vm.close()
        let draft = await make(repository); confirm(draft, manual: true); await wait { draft.careState == .loaded }
        let sheet = draft.careSheet, identity = draft.confirmedIdentity
        draft.changeConfirmedSpecies(); XCTAssertEqual(draft.manualDraft?.name, "Ficus lyrata"); XCTAssertNil(draft.reviewableCareSheet)
        draft.cancelManualSpecies(sessionID: draft.manualDraft!.id)
        XCTAssertEqual(draft.reviewableCareSheet, sheet); XCTAssertEqual(draft.confirmedIdentity, identity)
        draft.select { nil }; await wait { !draft.isLoading }; XCTAssertEqual(draft.careSheet, sheet)
        draft.select { Data([2]) }; await wait { !draft.isLoading }; XCTAssertNil(draft.careSheet); XCTAssertNil(draft.confirmedIdentity)
        draft.identifyPhoto(); await wait { !draft.isBusy }; confirm(draft); await wait { draft.careState == .loaded }
        draft.identifyPhoto(); XCTAssertNil(draft.careSheet); XCTAssertNil(draft.confirmedIdentity)
        await wait { !draft.isBusy }
    }

    func testConsentReadWriteFailuresAndConfigurationChangeDuringResponseBlockPublication() async {
        for writeFailure in [false, true] {
            let repository = CareRepositoryDouble(), consent = ConsentDouble()
            let vm = await make(repository, consent: consent)
            await consent.configure(failRead: !writeFailure, failWrite: writeFailure)
            confirm(vm)
            if writeFailure {
                await wait { vm.careState == .awaitingConsent }
                vm.confirmAuthorization()
            }
            await wait { vm.careState == .failed }
            let inputs = await repository.identities; XCTAssertTrue(inputs.isEmpty)
            XCTAssertNil(vm.careSheet); XCTAssertNotNil(vm.confirmedIdentity); XCTAssertNotNil(vm.photo)
        }
        let awaitingRepository = CareRepositoryDouble(), awaitingConsent = ConsentDouble()
        var noticeCurrent = true
        let awaiting = await make(awaitingRepository, consent: awaitingConsent, current: { noticeCurrent })
        await awaitingConsent.configure(value: nil)
        confirm(awaiting); await wait { awaiting.careState == .awaitingConsent }
        noticeCurrent = false; awaiting.confirmAuthorization()
        XCTAssertEqual(awaiting.careState, .failed); XCTAssertEqual(awaiting.careError, .configuration)
        XCTAssertEqual(awaiting.authorizationState, .idle); XCTAssertFalse(awaiting.isBusy)
        let blockedInputs = await awaitingRepository.identities; XCTAssertTrue(blockedInputs.isEmpty)
        let repository = CareRepositoryDouble(); await repository.configure(held: true)
        var current = true
        let vm = await make(repository, current: { current }); confirm(vm)
        await wait { vm.careState == .loading }
        current = false; await repository.release()
        await wait { vm.careState == .failed }
        XCTAssertEqual(vm.careError, .configuration); XCTAssertNil(vm.careSheet)
    }

    func testOldResponseCannotReplaceNewSameIdentityIntention() async {
        let repository = CareRepositoryDouble(); await repository.configure(held: true)
        let vm = await make(repository); confirm(vm)
        await wait { vm.careState == .loading }
        let identity = vm.confirmedIdentity
        vm.cancelCare()
        await repository.configure(sheet: CareSheet(light: "Nueva", watering: "R", humidity: "H", temperature: "T", substrate: "S", fertilizer: "A"))
        vm.retryCare(); await wait { vm.careState == .loaded }
        await repository.configure(sheet: CareSheet(light: "Vieja", watering: "R", humidity: "H", temperature: "T", substrate: "S", fertilizer: "A"))
        await repository.release()
        try? await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(vm.careSheet?.light, "Nueva"); XCTAssertEqual(vm.confirmedIdentity, identity)
        let inputs = await repository.identities; XCTAssertEqual(inputs, [identity!, identity!])
    }
}
