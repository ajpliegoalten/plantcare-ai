import XCTest
@testable import PlantCareAI

private struct ManualPhotoPreparer: IdentificationPhotoPreparing {
    func prepare(_ data: Data) async throws -> IdentificationPhoto {
        IdentificationPhoto(id: UUID(), jpeg: data, width: 2, height: 1)
    }
}

private final class ManualConfirmationDouble: ConfirmManualSpeciesUseCase {
    var fails = false
    var calls = 0
    func execute(photoID: UUID, name: String) throws -> ConfirmedDraftIdentity {
        calls += 1
        if fails { throw ConfirmManualSpeciesError.emptyName }
        return try ConfirmManualSpecies().execute(photoID: photoID, name: name)
    }
}

@MainActor
final class ManualSpeciesViewModelTests: XCTestCase {
    private let proposals = IdentificationResult(outcome: .proposals,
        primary: SpeciesCandidate(commonName: "Principal", scientificName: "Primary species"),
        alternatives: [SpeciesCandidate(commonName: "Alternativa", scientificName: nil)], uncertainty: "Orientativo")

    private func wait(_ predicate: () -> Bool) async {
        for _ in 0..<1000 {
            if predicate() { return }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("State did not settle")
    }

    private func make(camera: PhotoCameraDouble = PhotoCameraDouble(), repository: ConsentDouble = ConsentDouble(),
                      confirmation: any ConfirmManualSpeciesUseCase = ConfirmManualSpecies(), available: Bool = true,
                      current: @escaping () -> Bool = { true },
                      operation: ((IdentificationPhoto) async throws -> IdentificationContinuationResult)? = nil) async -> IdentificationPhotoViewModel {
        let result = proposals
        let vm = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: ManualPhotoPreparer()),
            camera: CheckCameraAccess(access: camera), authorize: AuthorizeExternalAIOperation(repository: repository),
            confirmManualSpecies: confirmation, identificationAvailable: available, configurationIsCurrent: current,
            identify: operation ?? { _ in .completed(result) })
        vm.select { Data([1]) }; await wait { vm.photo != nil }
        return vm
    }

    private func identify(_ vm: IdentificationPhotoViewModel) async {
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation || !vm.isBusy }
        if vm.authorizationState == .awaitingConfirmation { vm.confirmAuthorization() }
        await wait { !vm.isBusy }
    }

    private func manual(_ vm: IdentificationPhotoViewModel, name: String = "  Ficus lyrata \n") -> UUID {
        vm.beginManualSpecies()
        let session = vm.manualDraft!.id
        vm.updateManualName(name, sessionID: session)
        vm.confirmManualSpecies(sessionID: session)
        return session
    }

    func testSuccessfulZeroCandidatesExplicitConfirmationAndDoubleCallbacks() async {
        var calls = 0
        let empty = IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "No identificada")
        let vm = await make(operation: { _ in calls += 1; return .completed(empty) })
        XCTAssertFalse(vm.canEnterManualSpecies)
        vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft)
        await identify(vm)
        XCTAssertTrue(vm.canEnterManualSpecies)
        vm.beginManualSpecies(); let session = vm.manualDraft!.id
        XCTAssertEqual(vm.manualDraft?.name, "")
        vm.updateManualName(" \n\t", sessionID: session); vm.confirmManualSpecies(sessionID: session)
        XCTAssertNil(vm.confirmedIdentity); XCTAssertTrue(vm.hasManualConfirmationError)
        vm.updateManualName("  Ficus lyrata \n", sessionID: session)
        XCTAssertFalse(vm.hasManualConfirmationError); XCTAssertNil(vm.confirmedIdentity)
        vm.confirmManualSpecies(sessionID: session)
        let identity = vm.confirmedIdentity
        XCTAssertEqual(identity?.source, .manual(name: "Ficus lyrata")); XCTAssertEqual(identity?.photoID, vm.photo?.id)
        XCTAssertNil(vm.manualDraft)
        vm.confirmManualSpecies(sessionID: session); vm.cancelManualSpecies(sessionID: session)
        vm.updateManualName("Old", sessionID: session)
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(calls, 1)
        XCTAssertFalse(vm.canReturnToAIProposals)
    }

    func testCancelPreservesExactAIStateAndReopenIsEmpty() async {
        let vm = await make(); await identify(vm)
        let revision = vm.resultID!
        vm.selectProposal(.alternative(index: 0), resultID: revision); vm.confirmSpecies(resultID: revision)
        let identity = vm.confirmedIdentity, photo = vm.photo
        vm.beginManualSpecies(); let session = vm.manualDraft!.id
        XCTAssertEqual(vm.manualDraft?.name, "")
        vm.updateManualName("Cancelled", sessionID: session); vm.cancelManualSpecies(sessionID: session)
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(vm.photo, photo)
        XCTAssertEqual(vm.identificationResult, proposals); XCTAssertEqual(vm.resultID, revision)
        XCTAssertEqual(vm.selectedProposal, .alternative(index: 0))
        vm.beginManualSpecies(); XCTAssertEqual(vm.manualDraft?.name, "")
        XCTAssertNotEqual(vm.manualDraft?.id, session)
    }

    func testManualOverridesAIAndReturningPreservesSelectionButRequiresConfirmation() async {
        var calls = 0; let result = proposals
        let vm = await make(operation: { _ in calls += 1; return .completed(result) })
        await identify(vm); let revision = vm.resultID!
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        _ = manual(vm)
        XCTAssertEqual(vm.confirmedIdentity?.manualName, "Ficus lyrata"); XCTAssertNil(vm.confirmedIdentity?.resultID)
        XCTAssertTrue(vm.canReturnToAIProposals); XCTAssertFalse(vm.canSelectProposal)
        vm.returnToAIProposals()
        XCTAssertNil(vm.confirmedIdentity); XCTAssertEqual(vm.selectedProposal, .alternative(index: 0))
        XCTAssertEqual(vm.resultID, revision); XCTAssertEqual(vm.identificationResult, result)
        vm.confirmSpecies(resultID: revision)
        XCTAssertEqual(vm.confirmedIdentity?.commonName, "Alternativa"); XCTAssertEqual(calls, 1)
    }

    func testEditingPreloadsAndCancelFailureAndStaleSamePhotoSessionPreserveIdentity() async {
        let confirmation = ManualConfirmationDouble()
        let vm = await make(confirmation: confirmation); await identify(vm)
        let old = manual(vm); let identity = vm.confirmedIdentity
        vm.changeConfirmedSpecies(); let session = vm.manualDraft!.id
        XCTAssertEqual(vm.manualDraft?.name, "Ficus lyrata")
        vm.beginManualSpecies(); XCTAssertEqual(vm.manualDraft?.id, session) // no replacement on double open
        vm.updateManualName("New", sessionID: session)
        vm.updateManualName("Stale", sessionID: old); vm.confirmManualSpecies(sessionID: old); vm.cancelManualSpecies(sessionID: old)
        XCTAssertEqual(vm.manualDraft?.name, "New"); XCTAssertEqual(vm.confirmedIdentity, identity)
        confirmation.fails = true; vm.confirmManualSpecies(sessionID: session)
        XCTAssertTrue(vm.hasManualConfirmationError); XCTAssertEqual(vm.manualDraft?.name, "New")
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertNil(vm.identificationError)
        vm.cancelManualSpecies(sessionID: session); XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.changeConfirmedSpecies(); XCTAssertEqual(vm.manualDraft?.name, "Ficus lyrata")
        confirmation.fails = false
        let edited = vm.manualDraft!.id
        vm.updateManualName("New", sessionID: edited); vm.confirmManualSpecies(sessionID: edited)
        XCTAssertEqual(vm.confirmedIdentity?.manualName, "New"); XCTAssertNil(vm.manualDraft)
        XCTAssertEqual(confirmation.calls, 3)
    }

    func testEditorBlocksPhotoIntentionsButAllowsExclusiveAISelectionAndCloseInvalidatesSession() async {
        let vm = await make(); await identify(vm); let revision = vm.resultID!, photo = vm.photo
        _ = manual(vm); let identity = vm.confirmedIdentity
        vm.beginManualSpecies(); let session = vm.manualDraft!.id
        vm.select { Data([2]) }; vm.takePhoto(); vm.identifyPhoto(); vm.returnToAIProposals()
        XCTAssertTrue(vm.canSelectProposal); XCTAssertNil(vm.selectedProposal)
        XCTAssertFalse(vm.isBusy); XCTAssertFalse(vm.canIdentify)
        XCTAssertEqual(vm.photo, photo); XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(vm.manualDraft?.id, session)
        vm.selectProposal(.primary, resultID: revision)
        XCTAssertNil(vm.manualDraft); XCTAssertEqual(vm.selectedProposal, .primary)
        XCTAssertEqual(vm.confirmedIdentity, identity)
        XCTAssertTrue(vm.canConfirmSpecies)
        vm.updateManualName("Stale", sessionID: session); vm.confirmManualSpecies(sessionID: session)
        XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.confirmSpecies(resultID: revision)
        XCTAssertEqual(vm.confirmedIdentity?.commonName, "Principal")
        vm.close(); XCTAssertNil(vm.photo); XCTAssertNil(vm.confirmedIdentity); XCTAssertNil(vm.manualDraft)
        vm.updateManualName("Late", sessionID: session); vm.confirmManualSpecies(sessionID: session)
        vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft); XCTAssertNil(vm.confirmedIdentity)
    }

    func testBusyCameraAndEmptyDraftBlockManual() async {
        let camera = PhotoCameraDouble()
        let vm = await make(camera: camera)
        await identify(vm)
        vm.select { try await Task.sleep(for: .milliseconds(20)); return nil }
        vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft); await wait { !vm.isLoading }
        vm.takePhoto(); vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft); await wait { !vm.isCheckingCamera }
        XCTAssertTrue(vm.presentsCamera); vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft)
        vm.presentsCamera = false
        vm.identifyPhoto(); vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft)
        await wait { !vm.isBusy } // previously accepted consent, now another successful result
        vm.beginManualSpecies(); XCTAssertNotNil(vm.manualDraft)
        vm.close(); vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft)
        let empty = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: ManualPhotoPreparer()),
            camera: CheckCameraAccess(access: camera), authorize: AuthorizeExternalAIOperation(repository: ConsentDouble()))
        empty.beginManualSpecies(); empty.confirmManualSpecies(sessionID: UUID()); XCTAssertNil(empty.manualDraft)
    }

    func testReplacementFailureDeniedCameraPreservesAndSuccessNewUUIDClearsManual() async {
        let camera = PhotoCameraDouble(), vm = await make()
        await identify(vm)
        _ = manual(vm); let photo = vm.photo, identity = vm.confirmedIdentity
        vm.select { nil }; await wait { !vm.isLoading }
        XCTAssertEqual(vm.photo, photo); XCTAssertEqual(vm.confirmedIdentity, identity)
        let draft = await make(camera: camera); await identify(draft); _ = manual(draft); let before = draft.confirmedIdentity
        for status in [CameraAuthorization.denied, .restricted] {
            await camera.configure(status: status); draft.takePhoto(); await wait { !draft.isCheckingCamera }
            XCTAssertEqual(draft.confirmedIdentity, before)
        }
        vm.select { Data([1]) }; await wait { !vm.isLoading }
        XCTAssertNotEqual(vm.photo?.id, photo?.id); XCTAssertNil(vm.confirmedIdentity); XCTAssertNil(vm.manualDraft)
    }

    func testReidentifyInvalidatesBeforeConfigurationNoticeFailureAndInsufficient() async {
        var current = true
        let vm = await make(current: { current }); await identify(vm); _ = manual(vm)
        current = false; vm.identifyPhoto(); XCTAssertNil(vm.confirmedIdentity); XCTAssertEqual(vm.authorizationState, .unavailable)
        current = true; await identify(vm); _ = manual(vm)
        vm.identifyPhoto(); XCTAssertNil(vm.confirmedIdentity)
        vm.cancelAuthorization(); XCTAssertFalse(vm.canEnterManualSpecies)
        for outcome in [IdentificationContinuationResult.unavailable,
                         .completed(IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "Duda"))] {
            var next = IdentificationContinuationResult.completed(proposals)
            let draft = await make(operation: { _ in next }); await identify(draft); _ = manual(draft)
            next = outcome; await identify(draft)
            XCTAssertNil(draft.confirmedIdentity); XCTAssertFalse(draft.canReturnToAIProposals)
            if case .completed = outcome {
                _ = manual(draft); XCTAssertNotNil(draft.confirmedIdentity)
            } else {
                draft.beginManualSpecies(); XCTAssertNil(draft.manualDraft); XCTAssertFalse(draft.canEnterManualSpecies)
            }
        }
        var shouldFail = false; let result = proposals
        let failed = await make(operation: { _ in
            if shouldFail { throw SpeciesIdentificationError.network }
            return .completed(result)
        })
        await identify(failed); _ = manual(failed)
        shouldFail = true; await identify(failed); XCTAssertNil(failed.confirmedIdentity)
        failed.beginManualSpecies(); XCTAssertNil(failed.manualDraft); XCTAssertFalse(failed.canEnterManualSpecies)
        XCTAssertEqual(failed.identificationError, .network)
        shouldFail = false; await identify(failed); _ = manual(failed)
        XCTAssertEqual(failed.confirmedIdentity?.manualName, "Ficus lyrata")
    }

    func testCancelledNonCooperativeAILateResponseCannotReplaceManualOnSamePhoto() async {
        var continuation: CheckedContinuation<IdentificationContinuationResult, Never>?
        var slow = true; let result = proposals
        let vm = await make(operation: { _ in
            if slow { return await withCheckedContinuation { continuation = $0 } }
            return .completed(result)
        })
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation }
        vm.confirmAuthorization(); await wait { continuation != nil }
        vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft)
        vm.cancelAuthorization(); vm.beginManualSpecies(); XCTAssertNil(vm.manualDraft)
        slow = false; await identify(vm); _ = manual(vm); let identity = vm.confirmedIdentity
        let revision = vm.resultID
        continuation?.resume(returning: .completed(proposals))
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(vm.identificationResult, proposals)
        XCTAssertEqual(vm.resultID, revision)
    }

    func testInlineExclusiveSelectionCancelAfterSwitchAndCommonConfirmation() async {
        var calls = 0; let result = proposals
        let vm = await make(operation: { _ in calls += 1; return .completed(result) })
        await identify(vm); let revision = vm.resultID!
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        vm.beginManualSpecies(); let session = vm.manualDraft!.id
        XCTAssertNil(vm.selectedProposal); XCTAssertFalse(vm.canConfirmSelection)
        vm.updateManualName(" \n ", sessionID: session); XCTAssertFalse(vm.canConfirmSelection)
        let long = String(repeating: "Árbol común científico ", count: 100) + "fin"
        vm.updateManualName("  " + long + "\n", sessionID: session)
        XCTAssertTrue(vm.canConfirmSelection); vm.confirmSelection()
        let identity = vm.confirmedIdentity
        XCTAssertEqual(identity?.manualName, long); XCTAssertNil(vm.selectedProposal)
        vm.changeConfirmedSpecies(); let edited = vm.manualDraft!.id
        XCTAssertEqual(vm.manualDraft?.name, long)
        vm.updateManualName("Cambio", sessionID: edited)
        vm.selectProposal(.primary, resultID: revision)
        XCTAssertNil(vm.manualDraft); XCTAssertEqual(vm.selectedProposal, .primary)
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertTrue(vm.isSelectingSpecies)
        vm.cancelSpeciesSelection()
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertFalse(vm.isSelectingSpecies)
        vm.changeConfirmedSpecies(); vm.selectProposal(.primary, resultID: revision)
        vm.confirmSelection()
        XCTAssertEqual(vm.confirmedIdentity?.commonName, "Principal")
        XCTAssertFalse(vm.isSelectingSpecies); XCTAssertEqual(calls, 1)
        vm.confirmManualSpecies(sessionID: edited)
        XCTAssertEqual(vm.confirmedIdentity?.commonName, "Principal")
    }

    func testManualToggleAfterSuccessfulZeroCandidatesReleasesPhotoActionsAndDiscardsDraft() async {
        let empty = IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "No identificada")
        let vm = await make(operation: { _ in .completed(empty) }); await identify(vm)
        vm.toggleManualSpecies(); let session = vm.manualDraft!.id
        vm.updateManualName("Potus", sessionID: session)
        XCTAssertTrue(vm.canConfirmSelection); XCTAssertFalse(vm.canIdentify)
        vm.toggleManualSpecies()
        XCTAssertNil(vm.manualDraft); XCTAssertNil(vm.selectedProposal)
        XCTAssertFalse(vm.canConfirmSelection); XCTAssertTrue(vm.canIdentify)
        XCTAssertFalse(vm.isSelectingSpecies)
        vm.updateManualName("Late", sessionID: session)
        vm.toggleManualSpecies()
        XCTAssertEqual(vm.manualDraft?.name, "")
        XCTAssertNotEqual(vm.manualDraft?.id, session)
    }

    func testAIToggleAndSwitchDiscardManualTextWithExclusiveSelection() async {
        let vm = await make(); await identify(vm); let revision = vm.resultID!
        vm.selectProposal(.primary, resultID: revision)
        XCTAssertTrue(vm.canConfirmSelection)
        vm.selectProposal(.primary, resultID: revision)
        XCTAssertNil(vm.selectedProposal); XCTAssertFalse(vm.canConfirmSelection)
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        vm.toggleManualSpecies(); let session = vm.manualDraft!.id
        vm.updateManualName("Discard", sessionID: session)
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        XCTAssertNil(vm.manualDraft); XCTAssertEqual(vm.selectedProposal, .alternative(index: 0))
        vm.updateManualName("Late", sessionID: session); vm.confirmManualSpecies(sessionID: session)
        XCTAssertNil(vm.confirmedIdentity)
        vm.toggleManualSpecies(); XCTAssertEqual(vm.manualDraft?.name, "")
        vm.toggleManualSpecies()
        XCTAssertNil(vm.selectedProposal) // deselection does not restore an earlier AI option
        vm.selectProposal(.primary, resultID: revision)
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        XCTAssertEqual(vm.selectedProposal, .alternative(index: 0))
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        XCTAssertNil(vm.selectedProposal)
        vm.beginManualSpecies(); let cancelled = vm.manualDraft!.id
        vm.cancelManualSpecies(sessionID: cancelled)
        XCTAssertNil(vm.selectedProposal) // explicit cancel restores none after AI deselection
    }

    func testDeselectEditingManualPreservesConfirmedIdentity() async {
        let vm = await make(); await identify(vm); _ = manual(vm)
        let identity = vm.confirmedIdentity
        vm.changeConfirmedSpecies(); let session = vm.manualDraft!.id
        vm.updateManualName("Discard", sessionID: session)
        vm.toggleManualSpecies()
        XCTAssertEqual(vm.confirmedIdentity, identity)
        XCTAssertNil(vm.manualDraft); XCTAssertNil(vm.selectedProposal)
        XCTAssertTrue(vm.canIdentify); XCTAssertFalse(vm.canConfirmSelection)
        vm.cancelSpeciesSelection()
        XCTAssertFalse(vm.isSelectingSpecies); XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.changeConfirmedSpecies(); XCTAssertEqual(vm.manualDraft?.name, "Ficus lyrata")
    }

    func testNoManualBeforeAttemptUnavailableErrorOrCancelledIdentification() async {
        let initial = await make()
        initial.toggleManualSpecies(); XCTAssertNil(initial.manualDraft)
        XCTAssertFalse(initial.hasSuccessfulIdentification)
        initial.identifyPhoto(); await wait { initial.authorizationState == .awaitingConfirmation }
        XCTAssertFalse(initial.canEnterManualSpecies)
        initial.cancelAuthorization(); initial.beginManualSpecies(); XCTAssertNil(initial.manualDraft)
        for available in [false, true] {
            let unavailable = await make(available: available, operation: { _ in .unavailable })
            await identify(unavailable); unavailable.beginManualSpecies()
            XCTAssertNil(unavailable.manualDraft); XCTAssertFalse(unavailable.hasSuccessfulIdentification)
        }
        for error in [SpeciesIdentificationError.network, .timeout, .invalidResponse, .rateLimited] {
            let failed = await make(operation: { _ in throw error })
            await identify(failed); failed.toggleManualSpecies()
            XCTAssertFalse(failed.hasSuccessfulIdentification); XCTAssertNil(failed.manualDraft)
            XCTAssertEqual(failed.identificationError, error)
        }
    }
}
