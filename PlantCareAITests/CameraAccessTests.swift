import XCTest
@testable import PlantCareAI

actor PhotoCameraDouble: CameraAccess {
    var available = true
    var status: CameraAuthorization = .notDetermined
    var requests = 0
    var answer = true
    func isAvailable() -> Bool { available }
    func authorization() -> CameraAuthorization { status }
    func requestAuthorization() -> Bool {
        requests += 1
        status = answer ? .authorized : .denied
        return answer
    }
    func configure(available: Bool = true, status: CameraAuthorization, answer: Bool = true) {
        self.available = available; self.status = status; self.answer = answer
    }
}

final class CameraAccessTests: XCTestCase {
    func testNoPromptBeforeIntentAndOnlyOneAfterGrant() async throws {
        let double = PhotoCameraDouble()
        let useCase = CheckCameraAccess(access: double)
        let initial = await double.requests
        XCTAssertEqual(initial, 0)
        let first = try await useCase.execute()
        let second = try await useCase.execute()
        XCTAssertEqual(first, .authorized)
        XCTAssertEqual(second, .authorized)
        let count = await double.requests
        XCTAssertEqual(count, 1)
    }

    func testUnavailableDeniedRestrictedAndRecheck() async throws {
        let double = PhotoCameraDouble()
        let useCase = CheckCameraAccess(access: double)
        await double.configure(available: false, status: .notDetermined)
        let unavailable = try await useCase.execute()
        XCTAssertEqual(unavailable, .unavailable)
        for (status, result) in [(CameraAuthorization.denied, CameraAccessResult.denied), (.restricted, .restricted), (.authorized, .authorized)] {
            await double.configure(status: status)
            let actual = try await useCase.execute()
            XCTAssertEqual(actual, result)
        }
        let count = await double.requests
        XCTAssertEqual(count, 0)
        await double.configure(status: .notDetermined, answer: false)
        let denied = try await useCase.execute()
        XCTAssertEqual(denied, .denied)
    }

    func testCancelledIntentDoesNotRequestPermission() async {
        let double = PhotoCameraDouble()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await CheckCameraAccess(access: double).execute()
        }
        do { _ = try await task.value; XCTFail("Cancelled intent checked access") }
        catch { XCTAssertTrue(error is CancellationError) }
        let count = await double.requests
        XCTAssertEqual(count, 0)
    }
}
