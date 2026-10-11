import XCTest
@testable import PlantCareAI

actor CreationDouble: SaveConfirmedPlantUseCase {
    var snapshots: [ConfirmedPlantSnapshot] = []
    var fail = true
    var holdBeforeCommit = false
    var holdAfterCommit = false
    var continuation: CheckedContinuation<Void, Never>?
    func execute(_ snapshot: ConfirmedPlantSnapshot, willCommit: @escaping @Sendable () async throws -> Void) async throws -> Plant {
        snapshots.append(snapshot)
        if holdBeforeCommit { await withCheckedContinuation { continuation = $0 } }
        try await willCommit()
        if holdAfterCommit { await withCheckedContinuation { continuation = $0 } }
        if fail { throw PlantStorageError.storage }
        return try snapshot.plant()
    }
    func configure(fail: Bool = false, before: Bool = false, after: Bool = false) {
        self.fail = fail; holdBeforeCommit = before; holdAfterCommit = after
    }
    func release() { continuation?.resume(); continuation = nil }
}

@MainActor
final class SavePlantViewModelTests: XCTestCase {
    private func wait(_ predicate: @escaping () -> Bool) async {
        for _ in 0..<1000 { if predicate() { return }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTFail("State did not settle")
    }
    func make(save: CreationDouble, care: CareRepositoryDouble, current: @escaping () -> Bool = { true }, saved: @escaping (Plant) -> Void) async -> IdentificationPhotoViewModel {
        let result = IdentificationResult(outcome: .proposals, primary: SpeciesCandidate(commonName: "Ficus", scientificName: "Ficus lyrata"), alternatives: [], uncertainty: "Orientativo")
        let vm = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), camera: CheckCameraAccess(access: PhotoCameraDouble()), authorize: AuthorizeExternalAIOperation(repository: ConsentDouble()), generateCare: GenerateCareSheet(repository: care), saveConfirmedPlant: save, onSaved: saved, configurationIsCurrent: current, identify: { _ in .completed(result) })
        vm.select { StorageTestFixture.photo(1) }; await wait { !vm.isLoading }
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation || !vm.isBusy }
        if vm.authorizationState == .awaitingConfirmation { vm.confirmAuthorization() }
        await wait { !vm.isBusy }
        vm.selectProposal(.primary, resultID: vm.resultID!)
        return vm
    }
    func testLocalRetryStableSnapshotNoAIAndEditingCancelNoAutoWrite() async {
        let save = CreationDouble(), care = CareRepositoryDouble()
        var saved: [Plant] = []
        var current = true
        let vm = await make(save: save, care: care, current: { current }) { saved.append($0) }
        let before = await save.snapshots; XCTAssertTrue(before.isEmpty)
        vm.confirmSelection(); vm.confirmSelection(); await wait { vm.creationState == .failed }
        let identity = vm.confirmedIdentity
        vm.changeConfirmedSpecies(); vm.retrySave()
        vm.cancelSpeciesSelection()
        XCTAssertEqual(vm.creationState, .failed); XCTAssertEqual(vm.confirmedIdentity, identity)
        let one = await save.snapshots; XCTAssertEqual(one.count, 1)
        current = false // Local retry must not depend on today's API configuration or authorize/send again.
        await save.configure()
        vm.retrySave(); vm.retrySave(); await wait { vm.creationState == .saved }
        let attempts = await save.snapshots; XCTAssertEqual(attempts, [one[0], one[0]])
        let calls = await care.identities; XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(saved.count, 1); vm.retrySave(); vm.confirmSelection(); XCTAssertEqual(saved.count, 1)
    }
    func testCancelValidationCloseAndCommitLocksUntilExactlyOneCallback() async {
        for after in [false, true] {
            let save = CreationDouble(), care = CareRepositoryDouble()
            await save.configure(before: !after, after: after)
            var saved: [Plant] = []
            let vm = await make(save: save, care: care) { saved.append($0) }
            vm.confirmSelection(); await wait { vm.creationState == (after ? .saving : .validating) }
            let photo = vm.photo, identity = vm.confirmedIdentity
            vm.close()
            if after {
                XCTAssertFalse(vm.canClose); XCTAssertEqual(vm.photo, photo)
                vm.cancelCare(); vm.cancelCreation(); vm.changeConfirmedSpecies(); vm.select { Data([2]) }
                XCTAssertEqual(vm.confirmedIdentity, identity); XCTAssertEqual(vm.photo, photo)
            } else { XCTAssertNil(vm.photo) }
            await save.release()
            if after { await wait { vm.creationState == .saved }; XCTAssertEqual(saved.count, 1) }
            else { try? await Task.sleep(for: .milliseconds(20)); XCTAssertTrue(saved.isEmpty) }
        }
    }

    func testValidationCancellationThenPhotoReplacementInvalidatesLocalRetry() async {
        let save = CreationDouble(), care = CareRepositoryDouble()
        await save.configure(before: true)
        var saved: [Plant] = []
        let vm = await make(save: save, care: care) { saved.append($0) }
        vm.confirmSelection(); await wait { vm.creationState == .validating }
        vm.cancelCare(); XCTAssertEqual(vm.creationState, .failed)
        await save.release(); try? await Task.sleep(for: .milliseconds(20)); XCTAssertTrue(saved.isEmpty)
        vm.select { nil }; await wait { !vm.isLoading }; XCTAssertEqual(vm.creationState, .failed)
        vm.select { StorageTestFixture.photo(2) }; await wait { !vm.isLoading }
        XCTAssertEqual(vm.creationState, .idle); XCTAssertNil(vm.confirmedIdentity)
        vm.retrySave(); let attempts = await save.snapshots; XCTAssertEqual(attempts.count, 1)
    }
}
