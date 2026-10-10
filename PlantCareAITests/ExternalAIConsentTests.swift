import XCTest
@testable import PlantCareAI

actor ConsentDouble: ExternalAIConsentRepository {
    var value: ExternalAIConsent?
    var failRead = false
    var failWrite = false
    var pauseRead = false
    var pauseWrite = false
    var pending: CheckedContinuation<Void, Never>?
    var writes = 0
    func configure(value: ExternalAIConsent? = nil, failRead: Bool = false, failWrite: Bool = false, pauseRead: Bool = false, pauseWrite: Bool = false) {
        self.value = value; self.failRead = failRead; self.failWrite = failWrite
        self.pauseRead = pauseRead; self.pauseWrite = pauseWrite
    }
    func acceptance() async throws -> ExternalAIConsent? {
        if pauseRead { await withCheckedContinuation { pending = $0 } }
        if failRead { throw CocoaError(.fileReadUnknown) }
        return value
    }
    func record(_ consent: ExternalAIConsent) async throws {
        if pauseWrite { await withCheckedContinuation { pending = $0 } }
        if failWrite { throw CocoaError(.fileWriteUnknown) }
        value = consent; writes += 1
    }
    func resume() { pending?.resume(); pending = nil }
    var isWaiting: Bool { pending != nil }
}

final class ExternalAIConsentTests: XCTestCase {
    func testPhotoAndTextRequireConfirmationThenRecordBeforeInvocation() async throws {
        for payload in [Data([1]), Data("text context".utf8)] {
            let repository = ConsentDouble()
            let gate = AuthorizeExternalAIOperation(repository: repository)
            var calls = 0
            let blocked = try await gate.execute { calls += 1; return payload }
            guard case .requiresConfirmation = blocked else { return XCTFail("Not blocked") }
            XCTAssertEqual(calls, 0)
            let absent = try await repository.acceptance(); XCTAssertNil(absent)
            let accepted = try await gate.execute(confirmed: true) {
                let saved = try await repository.acceptance()
                XCTAssertEqual(saved, .current)
                calls += 1; return payload
            }
            guard case .completed(let result) = accepted else { return XCTFail("Not continued") }
            XCTAssertEqual(result, payload); XCTAssertEqual(calls, 1)
            _ = try await gate.execute { calls += 1 }
            XCTAssertEqual(calls, 2)
            let writes = await repository.writes; XCTAssertEqual(writes, 1)
        }
    }

    func testWrongScopeReadAndWriteFailuresFailClosed() async throws {
        let repository = ConsentDouble()
        let gate = AuthorizeExternalAIOperation(repository: repository)
        for scope in [ExternalAIConsent(recipient: "other", noticeVersion: 1), ExternalAIConsent(recipient: "prototype-external-ai", noticeVersion: 2)] {
            await repository.configure(value: scope)
            let result = try await gate.execute { XCTFail("Wrong scope invoked") }
            guard case .requiresConfirmation = result else { return XCTFail("Wrong scope accepted") }
        }
        for reading in [true, false] {
            await repository.configure(failRead: reading, failWrite: !reading)
            do {
                _ = try await gate.execute(confirmed: true) { XCTFail("Failure invoked") }
                XCTFail("Failure hidden")
            } catch {}
            let value = await repository.value; XCTAssertNil(value)
        }
    }

    func testCancellationBetweenReadRecordAndInvocation() async {
        for reading in [true, false] {
            let repository = ConsentDouble()
            await repository.configure(pauseRead: reading, pauseWrite: !reading)
            let gate = AuthorizeExternalAIOperation(repository: repository)
            let task = Task {
                try await gate.execute(confirmed: true) { XCTFail("Cancelled operation invoked") }
            }
            for _ in 0..<1000 {
                if await repository.isWaiting { break }
                await Task.yield()
            }
            let waiting = await repository.isWaiting; XCTAssertTrue(waiting)
            task.cancel(); await repository.resume()
            do { _ = try await task.value; XCTFail("Cancellation hidden") } catch { XCTAssertTrue(error is CancellationError) }
            let writes = await repository.writes; XCTAssertEqual(writes, reading ? 0 : 1)
        }
    }

    func testOperationFailurePropagatesWithoutRetryAndCancellationBeforeRead() async throws {
        let repository = ConsentDouble()
        await repository.configure(value: .current)
        let gate = AuthorizeExternalAIOperation(repository: repository)
        var calls = 0
        do {
            _ = try await gate.execute { calls += 1; throw CocoaError(.userCancelled) }
            XCTFail("Operation error hidden")
        } catch { XCTAssertEqual((error as? CocoaError)?.code, .userCancelled) }
        XCTAssertEqual(calls, 1)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await gate.execute { XCTFail("Precancelled operation invoked") }
        }
        do { _ = try await task.value; XCTFail("Cancellation hidden") } catch { XCTAssertTrue(error is CancellationError) }
    }
}
