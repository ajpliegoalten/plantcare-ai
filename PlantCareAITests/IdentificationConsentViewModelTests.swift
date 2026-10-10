import XCTest
@testable import PlantCareAI

private struct ConsentPhotoPreparer: IdentificationPhotoPreparing {
    func prepare(_ data: Data) async throws -> IdentificationPhoto {
        IdentificationPhoto(id: UUID(), jpeg: data, width: 2, height: 1)
    }
}

@MainActor
final class IdentificationConsentViewModelTests: XCTestCase {
    private func wait(_ predicate: () async -> Bool) async {
        for _ in 0..<1000 {
            if await predicate() { return }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("State did not settle")
    }
    private func make(_ repository: ConsentDouble, operation: @escaping (IdentificationPhoto) async throws -> IdentificationContinuationResult = { _ in .unavailable }) async -> IdentificationPhotoViewModel {
        let vm = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: ConsentPhotoPreparer()), camera: CheckCameraAccess(access: PhotoCameraDouble()), authorize: AuthorizeExternalAIOperation(repository: repository), identify: operation)
        vm.identifyPhoto(); XCTAssertEqual(vm.authorizationState, .idle)
        vm.select { Data([1]) }
        XCTAssertFalse(vm.canIdentify)
        vm.identifyPhoto(); XCTAssertEqual(vm.authorizationState, .idle)
        await wait { vm.photo != nil }
        XCTAssertEqual(vm.authorizationState, .idle)
        let value = await repository.value; XCTAssertNil(value)
        return vm
    }

    func testCancelDuplicateAcceptAndNextExplicitIntention() async throws {
        let repository = ConsentDouble()
        var calls = 0
        let vm = await make(repository) { _ in
            let saved = try await repository.acceptance(); XCTAssertEqual(saved, .current)
            calls += 1; return .unavailable
        }
        let a = vm.photo
        vm.identifyPhoto(); vm.identifyPhoto()
        await wait { vm.authorizationState == .awaitingConfirmation }
        XCTAssertEqual(calls, 0)
        vm.select { XCTFail("Replaced during confirmation"); return Data() }
        vm.cancelAuthorization()
        XCTAssertEqual(vm.photo, a)
        let saved = await repository.value; XCTAssertNil(saved)
        vm.confirmAuthorization(); XCTAssertEqual(calls, 0)
        vm.identifyPhoto()
        await wait { vm.authorizationState == .awaitingConfirmation }
        vm.confirmAuthorization(); vm.confirmAuthorization(); vm.identifyPhoto()
        await wait { vm.authorizationState == .unavailable }
        XCTAssertEqual(calls, 1); XCTAssertEqual(vm.photo, a)
        vm.identifyPhoto()
        await wait { vm.authorizationState == .unavailable }
        XCTAssertEqual(calls, 2)
    }

    func testReadWriteErrorsPreservePhotoAndRetry() async {
        for read in [true, false] {
            let repository = ConsentDouble()
            await repository.configure(failRead: read, failWrite: !read)
            let vm = await make(repository) { _ in XCTFail("Failure invoked"); return .unavailable }
            let a = vm.photo
            vm.identifyPhoto()
            await wait { vm.authorizationState == (read ? .failed : .awaitingConfirmation) }
            if !read { vm.confirmAuthorization(); await wait { vm.authorizationState == .failed } }
            XCTAssertEqual(vm.photo, a)
            await repository.configure()
            vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation }
            vm.close(); vm.confirmAuthorization()
            XCTAssertEqual(vm.authorizationState, .idle)
        }
    }

    func testCloseDuringLateReadOrRecordNeverInvokesOrReopens() async {
        for read in [true, false] {
            let repository = ConsentDouble()
            await repository.configure(pauseRead: read, pauseWrite: !read)
            let vm = await make(repository) { _ in XCTFail("Closed operation invoked"); return .unavailable }
            vm.identifyPhoto()
            if !read {
                await wait { vm.authorizationState == .awaitingConfirmation }
                vm.confirmAuthorization()
            }
            await wait { await repository.isWaiting }
            vm.close(); await repository.resume()
            try? await Task.sleep(for: .milliseconds(20))
            XCTAssertNil(vm.photo); XCTAssertEqual(vm.authorizationState, .idle)
            let writes = await repository.writes; XCTAssertEqual(writes, read ? 0 : 1)
        }
    }

    func testCancelImmediatelyAfterConfirmAndLateContinuationCannotPublish() async {
        let repository = ConsentDouble()
        let vm = await make(repository) { _ in XCTFail("Cancelled before start invoked"); return .unavailable }
        vm.identifyPhoto(); await wait { vm.authorizationState == .awaitingConfirmation }
        vm.confirmAuthorization(); vm.cancelAuthorization()
        try? await Task.sleep(for: .milliseconds(20))
        let value = await repository.value; XCTAssertNil(value)
        XCTAssertEqual(vm.authorizationState, .idle)
        XCTAssertNotNil(vm.photo)

        var completion: CheckedContinuation<IdentificationContinuationResult, Never>?
        let late = await make(repository) { _ in
            await withCheckedContinuation { completion = $0 }
        }
        late.identifyPhoto(); await wait { late.authorizationState == .awaitingConfirmation }
        late.confirmAuthorization(); await wait { completion != nil }
        late.close(); completion?.resume(returning: .unavailable)
        try? await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(late.authorizationState, .idle); XCTAssertNil(late.photo)
        let accepted = await repository.value; XCTAssertEqual(accepted, .current)
    }
}
