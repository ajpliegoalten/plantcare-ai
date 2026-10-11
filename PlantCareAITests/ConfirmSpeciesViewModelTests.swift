import XCTest
@testable import PlantCareAI

private struct DraftPhotoPreparer: IdentificationPhotoPreparing {
    func prepare(_ data: Data) async throws -> IdentificationPhoto {
        IdentificationPhoto(id: UUID(), jpeg: data, width: 2, height: 1)
    }
}

private struct FailingConfirmation: ConfirmSpeciesUseCase {
    func execute(photoID: UUID, resultID: UUID, result: IdentificationResult, selection: SpeciesProposalSelection) throws -> ConfirmedDraftIdentity {
        throw ConfirmSpeciesError.invalidResult
    }
}

@MainActor
final class ConfirmSpeciesViewModelTests: XCTestCase {
    private let proposals = IdentificationResult(outcome: .proposals,
        primary: SpeciesCandidate(commonName: "Principal", scientificName: "Primary species"),
        alternatives: [SpeciesCandidate(commonName: "Alternativa", scientificName: "Alternative species")], uncertainty: "Es orientativo.")

    private func wait(_ predicate: () -> Bool) async {
        for _ in 0..<1000 {
            if predicate() { return }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("State did not settle")
    }

    private func make(repository: ConsentDouble = ConsentDouble(), camera: PhotoCameraDouble = PhotoCameraDouble(),
                      confirmation: any ConfirmSpeciesUseCase = ConfirmSpecies(), current: @escaping () -> Bool = { true },
                      operation: ((IdentificationPhoto) async throws -> IdentificationContinuationResult)? = nil) async -> IdentificationPhotoViewModel {
        let result = proposals
        let vm = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: DraftPhotoPreparer()),
            camera: CheckCameraAccess(access: camera), authorize: AuthorizeExternalAIOperation(repository: repository),
            confirmSpecies: confirmation, configurationIsCurrent: current,
            identify: operation ?? { _ in .completed(result) })
        vm.select { Data([1]) }; await wait { vm.photo != nil }
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation }
        vm.confirmAuthorization(); await wait { !vm.isBusy }
        return vm
    }

    private func confirm(_ vm: IdentificationPhotoViewModel, selection: SpeciesProposalSelection = .alternative(index: 0)) {
        guard let revision = vm.resultID else { XCTFail("Missing revision"); return }
        vm.selectProposal(selection, resultID: revision)
        vm.confirmSpecies(resultID: revision)
    }

    func testNoPreselectionUniqueChoiceExactAlternativeAndIdempotence() async {
        var calls = 0
        let result = proposals
        let vm = await make { _ in calls += 1; return .completed(result) }
        let revision = vm.resultID!
        XCTAssertNil(vm.selectedProposal); XCTAssertNil(vm.confirmedIdentity); XCTAssertFalse(vm.canConfirmSpecies)
        vm.confirmSpecies(resultID: revision); XCTAssertNil(vm.confirmedIdentity)
        vm.selectProposal(.primary, resultID: revision); XCTAssertNil(vm.confirmedIdentity)
        vm.selectProposal(.alternative(index: 0), resultID: revision)
        XCTAssertEqual(vm.selectedProposal, .alternative(index: 0))
        vm.confirmSpecies(resultID: revision)
        let identity = vm.confirmedIdentity
        XCTAssertEqual(identity?.commonName, "Alternativa"); XCTAssertEqual(identity?.scientificName, "Alternative species")
        XCTAssertEqual(identity?.photoID, vm.photo?.id); XCTAssertEqual(identity?.resultID, revision)
        vm.confirmSpecies(resultID: revision); vm.selectProposal(.primary, resultID: revision)
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(vm.resultID, revision); XCTAssertEqual(calls, 1)
        vm.changeConfirmedSpecies()
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertTrue(vm.isSelectingSpecies)
        XCTAssertEqual(vm.selectedProposal, .alternative(index: 0))
        vm.selectProposal(.primary, resultID: revision); XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.confirmSpecies(resultID: revision); XCTAssertEqual(vm.confirmedIdentity?.commonName, "Principal")
        XCTAssertEqual(calls, 1)
    }

    func testFailedReplacementCancellationAndCameraPreserveIdentityButBusyBlocks() async {
        let camera = PhotoCameraDouble()
        let vm = await make(camera: camera)
        confirm(vm)
        let identity = vm.confirmedIdentity!, photo = vm.photo, revision = vm.resultID!
        var transfer: CheckedContinuation<Data?, Error>?
        vm.select { try await withCheckedThrowingContinuation { transfer = $0 } }
        await wait { transfer != nil }
        vm.changeConfirmedSpecies(); vm.confirmSpecies(resultID: revision)
        XCTAssertFalse(vm.canSelectProposal); XCTAssertEqual(vm.confirmedIdentity, identity)
        transfer?.resume(throwing: IdentificationPhotoError.transferFailed)
        await wait { !vm.isLoading }
        XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(vm.photo, photo)
        XCTAssertEqual(vm.identificationResult, proposals); XCTAssertEqual(vm.resultID, revision)
        // Picker cancellation makes no transfer call; denied/unavailable camera also preserves A.
        for status in [CameraAuthorization.denied, .restricted] {
            await camera.configure(status: status); vm.takePhoto()
            XCTAssertFalse(vm.canSelectProposal); await wait { !vm.isCheckingCamera }
            XCTAssertEqual(vm.confirmedIdentity, identity)
        }
        await camera.configure(status: .authorized); vm.takePhoto(); await wait { vm.presentsCamera }
        XCTAssertFalse(vm.canConfirmSpecies); vm.changeConfirmedSpecies(); XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.presentsCamera = false
        XCTAssertEqual(vm.confirmedIdentity, identity)
        vm.select { Data([1]) }; await wait { !vm.isLoading }
        XCTAssertNotEqual(vm.photo?.id, photo?.id) // same bytes/resource, new selection UUID
        XCTAssertNil(vm.confirmedIdentity); XCTAssertNil(vm.selectedProposal); XCTAssertNil(vm.resultID)
        vm.selectProposal(.primary, resultID: revision); vm.confirmSpecies(resultID: revision)
        XCTAssertNil(vm.confirmedIdentity)
    }

    func testReidentificationClearsBeforeConfigurationAndNoticeCancellation() async {
        let repository = ConsentDouble()
        var current = true
        let vm = await make(repository: repository, current: { current })
        confirm(vm); let photo = vm.photo, old = vm.resultID!
        current = false; vm.identifyPhoto()
        XCTAssertNil(vm.resultID); XCTAssertNil(vm.confirmedIdentity); XCTAssertNil(vm.selectedProposal)
        XCTAssertEqual(vm.authorizationState, .unavailable); XCTAssertEqual(vm.photo, photo)
        current = true
        await repository.configure(value: nil)
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation }
        vm.selectProposal(.primary, resultID: old); vm.confirmSpecies(resultID: old)
        XCTAssertNil(vm.confirmedIdentity)
        vm.cancelAuthorization(); XCTAssertNil(vm.confirmedIdentity); XCTAssertEqual(vm.photo, photo)
    }

    func testSameNamesNewRevisionAndOldActionsIgnored() async {
        let vm = await make(); confirm(vm)
        let old = vm.resultID!, photo = vm.photo
        vm.identifyPhoto(); XCTAssertNil(vm.confirmedIdentity)
        await wait { vm.resultID != nil }
        XCTAssertNotEqual(vm.resultID, old); XCTAssertEqual(vm.photo, photo)
        XCTAssertNil(vm.selectedProposal)
        vm.selectProposal(.primary, resultID: old); vm.confirmSpecies(resultID: old)
        XCTAssertNil(vm.confirmedIdentity); XCTAssertNil(vm.selectedProposal)
        confirm(vm, selection: .primary); XCTAssertEqual(vm.confirmedIdentity?.resultID, vm.resultID)
    }

    func testFailureInsufficientUnavailableAndInvalidSelectionNeverConfirm() async {
        for outcome in [IdentificationContinuationResult.unavailable,
                        .completed(IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "Duda"))] {
            let vm = await make(operation: { _ in outcome })
            vm.selectProposal(.primary, resultID: vm.resultID ?? UUID()); vm.confirmSpecies(resultID: vm.resultID ?? UUID())
            XCTAssertNil(vm.confirmedIdentity); XCTAssertFalse(vm.canSelectProposal)
        }
        var calls = 0; let result = proposals
        let vm = await make { _ in
            calls += 1
            if calls > 1 { throw SpeciesIdentificationError.network }
            return .completed(result)
        }
        let revision = vm.resultID!
        for index in [-1, 1, Int.max] { vm.selectProposal(.alternative(index: index), resultID: revision) }
        XCTAssertNil(vm.selectedProposal)
        confirm(vm); vm.identifyPhoto(); XCTAssertNil(vm.confirmedIdentity)
        await wait { vm.authorizationState == .failed }
        XCTAssertNil(vm.resultID); XCTAssertNil(vm.confirmedIdentity); XCTAssertNotNil(vm.photo)
    }

    func testCancelledAndClosedLateContinuationsCannotReviveDraft() async {
        for closing in [false, true] {
            var continuation: CheckedContinuation<IdentificationContinuationResult, Never>?
            var calls = 0; let result = proposals
            let vm = await make { _ in
                calls += 1
                if calls == 1 { return .completed(result) }
                return await withCheckedContinuation { continuation = $0 }
            }
            confirm(vm); let old = vm.resultID!
            vm.identifyPhoto(); await wait { continuation != nil }
            XCTAssertFalse(vm.canSelectProposal); XCTAssertNil(vm.confirmedIdentity)
            if closing { vm.close() } else { vm.cancelAuthorization() }
            continuation?.resume(returning: .completed(result))
            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertNil(vm.identificationResult); XCTAssertNil(vm.confirmedIdentity); XCTAssertNil(vm.resultID)
            vm.selectProposal(.primary, resultID: old); vm.confirmSpecies(resultID: old)
            XCTAssertNil(vm.confirmedIdentity)
            if closing { XCTAssertNil(vm.photo) } else { XCTAssertNotNil(vm.photo) }
        }
        let vm = await make(); confirm(vm); vm.close()
        XCTAssertNil(vm.photo); XCTAssertNil(vm.selectedProposal); XCTAssertNil(vm.confirmedIdentity)
    }

    func testContractFailureIsLocalNotAPIError() async {
        let vm = await make(confirmation: FailingConfirmation())
        confirm(vm)
        XCTAssertNil(vm.confirmedIdentity); XCTAssertTrue(vm.hasConfirmationError)
        XCTAssertNil(vm.identificationError); XCTAssertEqual(vm.authorizationState, .idle)
    }

    func testSelectionOnlyReplacementAndReidentifiedNonProposalStates() async {
        let vm = await make(), revision = UUID()
        vm.selectProposal(.primary, resultID: revision); XCTAssertNil(vm.selectedProposal)
        vm.selectProposal(.primary, resultID: vm.resultID!)
        let oldRevision = vm.resultID
        vm.select { nil }; await wait { !vm.isLoading }
        XCTAssertEqual(vm.selectedProposal, .primary); XCTAssertEqual(vm.resultID, oldRevision)
        XCTAssertNil(vm.confirmedIdentity)
        vm.select { Data([2]) }; await wait { !vm.isLoading }
        XCTAssertNil(vm.selectedProposal); XCTAssertNil(vm.resultID)
        for outcome in [IdentificationContinuationResult.unavailable,
                        .completed(IdentificationResult(outcome: .insufficientEvidence, primary: nil, alternatives: [], uncertainty: "Duda")),
                        .completed(IdentificationResult(outcome: .proposals, primary: nil, alternatives: [], uncertainty: "Inválido"))] {
            var calls = 0; let proposals = self.proposals
            let draft = await make { _ in calls += 1; return calls == 1 ? .completed(proposals) : outcome }
            confirm(draft); draft.identifyPhoto()
            XCTAssertNil(draft.confirmedIdentity); XCTAssertNil(draft.selectedProposal)
            await wait { !draft.isBusy }
            draft.selectProposal(.primary, resultID: draft.resultID ?? UUID())
            draft.confirmSpecies(resultID: draft.resultID ?? UUID())
            XCTAssertNil(draft.confirmedIdentity); XCTAssertNil(draft.selectedProposal)
        }
        let empty = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: DraftPhotoPreparer()),
            camera: CheckCameraAccess(access: PhotoCameraDouble()), authorize: AuthorizeExternalAIOperation(repository: ConsentDouble()))
        empty.selectProposal(.primary, resultID: UUID()); empty.confirmSpecies(resultID: UUID())
        XCTAssertNil(empty.confirmedIdentity); XCTAssertFalse(empty.canSelectProposal)
    }
}
