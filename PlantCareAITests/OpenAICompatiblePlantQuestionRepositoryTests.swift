import XCTest
@testable import PlantCareAI

final class OpenAICompatiblePlantQuestionRepositoryTests: XCTestCase {
    func testOfflineAndTimeoutAreTypedAndNeverRetried() async throws {
        let context = try BuildPlantQuestionContextTests().build()
        for (code, expected) in [(URLError.notConnectedToInternet, PlantQuestionError.network), (.timedOut, .timeout)] {
            IdentificationURLProtocol.requests = 0
            IdentificationURLProtocol.handler = { _ in throw URLError(code) }
            do { _ = try await adapter().ask(context: context); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, expected) }
            XCTAssertEqual(IdentificationURLProtocol.requests, 1)
        }
    }
    override func tearDown() {
        IdentificationURLProtocol.handler = nil; IdentificationURLProtocol.requests = 0; IdentificationURLProtocol.hold = false; IdentificationURLProtocol.stopped = false
        super.tearDown()
    }
    func adapter(key: String? = nil, current: @escaping @Sendable () -> Bool = { true }) throws -> OpenAICompatiblePlantQuestionRepository {
        let session = URLSessionConfiguration.ephemeral; session.protocolClasses = [IdentificationURLProtocol.self]
        return try .init(configuration: IdentificationAPIConfiguration(baseURL: "https://question.invalid/v1", model: "text", key: key), sessionConfiguration: session, configurationIsCurrent: current)
    }
    func envelope(_ text: String = #"{"answer":"Comprueba antes de actuar 🌱"}"#, finish: String = "stop") throws -> Data {
        try JSONSerialization.data(withJSONObject: ["choices": [["finish_reason": finish, "message": ["content": text]]]])
    }
    func body(_ request: URLRequest) throws -> [String: Any] {
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open(); defer { stream.close() }; var bytes = Data(), buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable { let n = stream.read(&buffer, maxLength: buffer.count); if n <= 0 { break }; bytes.append(contentsOf: buffer.prefix(n)) }; data = bytes
        }
        return try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(data)) as? [String: Any])
    }
    func testTextOnlyTwoMessagesExactJSONOptionalAuthNoPreviousConversation() async throws {
        let context = try BuildPlantQuestionContextTests().build(), response = try envelope()
        for key in [nil, "synthetic"] as [String?] {
            IdentificationURLProtocol.requests = 0
            IdentificationURLProtocol.handler = { request in
                XCTAssertEqual(request.httpMethod, "POST"); XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), key.map { "Bearer " + $0 })
                let body = try self.body(request), messages = try XCTUnwrap(body["messages"] as? [[String: Any]])
                XCTAssertEqual(Set(body.keys), ["model", "stream", "max_tokens", "messages"]); XCTAssertEqual(body["max_tokens"] as? Int, 2000)
                XCTAssertEqual(body["stream"] as? Bool, false); XCTAssertEqual(messages.count, 2)
                XCTAssertEqual(messages[0]["content"] as? String, OpenAICompatiblePlantQuestionRepository.prompt)
                let text = try XCTUnwrap(messages[1]["content"] as? String)
                XCTAssertEqual(try JSONDecoder().decode(PlantQuestionContext.self, from: Data(text.utf8)), context)
                XCTAssertFalse(text.contains("image_url")); XCTAssertFalse(text.contains("NO ENVIAR NOMBRE"))
                return (200, response)
            }
            let result = try await adapter(key: key).ask(context: context)
            XCTAssertEqual(result.answer, "Comprueba antes de actuar 🌱"); XCTAssertEqual(IdentificationURLProtocol.requests, 1)
        }
    }
    func testStrictDecoderRejectsKeysTypesBlankLengthTruncationAndEnvelope() throws {
        for text in [#"{"answer":" "}"#, #"{"answer":1}"#, #"{"answer":"ok","extra":1}"#, "not JSON"] {
            XCTAssertThrowsError(try OpenAICompatiblePlantQuestionRepository.decode(envelope(text)))
        }
        let long = String(decoding: try JSONEncoder().encode(PlantQuestionAnswer(answer: String(repeating: "x", count: 6001))), as: UTF8.self)
        XCTAssertThrowsError(try OpenAICompatiblePlantQuestionRepository.decode(envelope(long)))
        for finish in ["length", "tool_calls", "content_filter"] { XCTAssertThrowsError(try OpenAICompatiblePlantQuestionRepository.decode(envelope(finish: finish))) }
        XCTAssertThrowsError(try OpenAICompatiblePlantQuestionRepository.decode(Data(repeating: 0, count: 1048577)))
    }
    func testHTTPFailuresOneRequestNoAutomaticRetryAndConfigurationNoHTTP() async throws {
        let context = try BuildPlantQuestionContextTests().build()
        for (status, expected) in [(401, PlantQuestionError.unauthorized), (403, .unauthorized), (429, .rateLimited), (422, .rejected), (500, .service)] {
            IdentificationURLProtocol.requests = 0; IdentificationURLProtocol.handler = { _ in (status, Data()) }
            do { _ = try await adapter().ask(context: context); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, expected) }
            XCTAssertEqual(IdentificationURLProtocol.requests, 1)
        }
        IdentificationURLProtocol.requests = 0
        do { _ = try await adapter(current: { false }).ask(context: context); XCTFail() } catch { XCTAssertEqual(error as? PlantQuestionError, .configuration) }
        XCTAssertEqual(IdentificationURLProtocol.requests, 0)
    }
    func testCancellationReachesSession() async throws {
        IdentificationURLProtocol.hold = true
        let context = try BuildPlantQuestionContextTests().build(), adapter = try adapter(), task = Task { try await adapter.ask(context: context) }
        for _ in 0..<1000 where IdentificationURLProtocol.requests == 0 { try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(IdentificationURLProtocol.requests, 1); task.cancel()
        do { _ = try await task.value; XCTFail() } catch { XCTAssertTrue(error is CancellationError) }
        for _ in 0..<1000 where !IdentificationURLProtocol.stopped { try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertTrue(IdentificationURLProtocol.stopped)
    }
}
