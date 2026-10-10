import XCTest
@testable import PlantCareAI

private actor ControlledPhotoPreparer: IdentificationPhotoPreparing {
    private var continuations: [CheckedContinuation<IdentificationPhoto, Error>] = []
    func prepare(_ data: Data) async throws -> IdentificationPhoto {
        try await withCheckedThrowingContinuation { continuations.append($0) }
    }
    var count: Int { continuations.count }
    func complete(_ result: Result<IdentificationPhoto, Error>) { continuations.removeFirst().resume(with: result) }
}

@MainActor
final class IdentificationPhotoViewModelTests: XCTestCase {
    private func wait(_ predicate: () async -> Bool) async {
        for _ in 0..<1000 {
            if await predicate() { return }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTFail("State did not settle")
    }
    private func make(_ preparer: ControlledPhotoPreparer) -> IdentificationPhotoViewModel {
        IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: preparer), camera: CheckCameraAccess(access: PhotoCameraDouble()), authorize: AuthorizeExternalAIOperation(repository: ConsentDouble()))
    }
    private func photo() -> IdentificationPhoto { IdentificationPhoto(id: UUID(), jpeg: Data([1]), width: 2, height: 1) }

    func testFirstReplacementFailureAndDuplicateSelection() async {
        let preparer = ControlledPhotoPreparer()
        let vm = make(preparer)
        let a = photo(), b = photo()
        vm.select { Data([1]) }
        vm.select { XCTFail("Duplicate transfer started"); return Data([2]) }
        await wait { await preparer.count == 1 }
        XCTAssertTrue(vm.isLoading)
        await preparer.complete(.success(a))
        await wait { !vm.isLoading }
        XCTAssertEqual(vm.photo, a)
        // Cancelling a system picker invokes no selection; the current image stays.
        XCTAssertNil(vm.error)
        vm.select { throw IdentificationPhotoError.transferFailed }
        await wait { !vm.isLoading }
        XCTAssertEqual(vm.photo, a)
        XCTAssertEqual(vm.error, .transferFailed)
        vm.select { Data([2]) }
        await wait { await preparer.count == 1 }
        XCTAssertEqual(vm.photo, a)
        await preparer.complete(.success(b))
        await wait { !vm.isLoading }
        XCTAssertEqual(vm.photo, b)
    }

    func testFailureWithoutPhotoCloseLateResponseAndNewOpening() async {
        let preparer = ControlledPhotoPreparer()
        let vm = make(preparer)
        vm.select { nil }
        await wait { !vm.isLoading }
        XCTAssertNil(vm.photo)
        XCTAssertEqual(vm.error, .transferFailed)
        vm.select { Data([1]) }
        await wait { await preparer.count == 1 }
        vm.close()
        await preparer.complete(.success(photo()))
        await Task.yield()
        XCTAssertNil(vm.photo)
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.isLoading)
        vm.select { XCTFail("Closed flow transferred"); return Data() }
        XCTAssertNil(make(preparer).photo)
    }

    func testCameraIssuePreservesPhotoAndClosedAuthorizationCannotPresent() async {
        let preparer = ControlledPhotoPreparer()
        let camera = PhotoCameraDouble()
        await camera.configure(available: false, status: .notDetermined)
        let vm = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: preparer), camera: CheckCameraAccess(access: camera), authorize: AuthorizeExternalAIOperation(repository: ConsentDouble()))
        let a = photo()
        vm.select { Data([1]) }
        await wait { await preparer.count == 1 }
        await preparer.complete(.success(a))
        await wait { !vm.isLoading }
        vm.takePhoto()
        XCTAssertFalse(vm.canIdentify)
        await wait { !vm.isCheckingCamera }
        XCTAssertEqual(vm.cameraIssue, .unavailable)
        XCTAssertEqual(vm.photo, a)
        XCTAssertFalse(vm.presentsCamera)
        await camera.configure(status: .authorized)
        vm.takePhoto()
        vm.close()
        await Task.yield()
        XCTAssertFalse(vm.presentsCamera)
    }
}
