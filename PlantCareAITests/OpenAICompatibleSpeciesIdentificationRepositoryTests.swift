import XCTest
@testable import PlantCareAI

final class IdentificationURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private static var storedHandler: ((URLRequest) throws -> (Int, Data))?
    private static var storedRequests = 0
    private static var storedHold = false
    private static var storedStopped = false
    static var handler: ((URLRequest) throws -> (Int, Data))? {
        get { lock.withLock { storedHandler } }
        set { lock.withLock { storedHandler = newValue } }
    }
    static var requests: Int {
        get { lock.withLock { storedRequests } }
        set { lock.withLock { storedRequests = newValue } }
    }
    static var hold: Bool {
        get { lock.withLock { storedHold } }
        set { lock.withLock { storedHold = newValue } }
    }
    static var stopped: Bool {
        get { lock.withLock { storedStopped } }
        set { lock.withLock { storedStopped = newValue } }
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.withLock { Self.storedRequests += 1 }
        if Self.hold { return }
        do {
            let (status, data) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() { Self.stopped = true }
}

final class OpenAICompatibleSpeciesIdentificationRepositoryTests: XCTestCase {
    override func tearDown() { IdentificationURLProtocol.handler = nil; IdentificationURLProtocol.requests = 0; IdentificationURLProtocol.hold = false; IdentificationURLProtocol.stopped = false; super.tearDown() }

    private func config(key: String? = "synthetic-key") throws -> IdentificationAPIConfiguration {
        try IdentificationAPIConfiguration(baseURL: "https://inference.devexpert.io/v1", model: "chat", key: key)
    }
    private func adapter(_ configuration: IdentificationAPIConfiguration? = nil) throws -> OpenAICompatibleSpeciesIdentificationRepository {
        let session = URLSessionConfiguration.ephemeral
        session.protocolClasses = [IdentificationURLProtocol.self]
        return try OpenAICompatibleSpeciesIdentificationRepository(configuration: configuration ?? config(), sessionConfiguration: session)
    }
    private let photo = IdentificationPhoto(id: UUID(), jpeg: Data([0xff, 0xd8, 3, 0xff, 0xd9]), width: 2, height: 1)
    private func envelope(content: String, finish: String = "stop", refusal: String? = nil) throws -> Data {
        var message: [String: Any] = ["content": content]
        if let refusal { message["refusal"] = refusal }
        return try JSONSerialization.data(withJSONObject: ["choices": [["finish_reason": finish, "message": message]]])
    }
    private let proposals = #"{"outcome":"proposals","primary":{"commonName":"Monstera","scientificName":"Monstera deliciosa"},"alternatives":[],"uncertainty":"Podría ser esta especie, sin confirmarla."}"#

    func testExactlyOneVisionRequestOnlyCurrentPhotoAndPrompt() async throws {
        let data = try envelope(content: proposals)
        let jpeg = photo.jpeg
        IdentificationURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://inference.devexpert.io/v1/chat/completions")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer synthetic-key")
            var body = request.httpBody
            if body == nil, let stream = request.httpBodyStream {
                stream.open(); defer { stream.close() }
                var collected = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
                while stream.hasBytesAvailable { let count = stream.read(&buffer, maxLength: buffer.count); if count <= 0 { break }; collected.append(contentsOf: buffer.prefix(count)) }
                body = collected
            }
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(body)) as? [String: Any])
            XCTAssertEqual(Set(object.keys), Set(["model", "stream", "max_tokens", "messages"]))
            XCTAssertEqual(object["model"] as? String, "chat")
            let messages = try XCTUnwrap(object["messages"] as? [[String: Any]])
            XCTAssertEqual(messages.count, 1)
            let content = try XCTUnwrap(messages[0]["content"] as? [[String: Any]])
            XCTAssertEqual(content.count, 2)
            XCTAssertEqual(content[0]["text"] as? String, OpenAICompatibleSpeciesIdentificationRepository.prompt)
            XCTAssertEqual((content[1]["image_url"] as? [String: String])?["url"], "data:image/jpeg;base64," + jpeg.base64EncodedString())
            return (200, data)
        }
        let repository = try adapter()
        let result = try await repository.identify(photo: photo)
        XCTAssertEqual(result.primary?.scientificName, "Monstera deliciosa")
        XCTAssertTrue(result.alternatives.isEmpty)
        XCTAssertEqual(IdentificationURLProtocol.requests, 1)
    }

    func testHTTPIsBlockedUntilRenewedRecipientAcceptanceThenOnePerExplicitIntention() async throws {
        let repository = ConsentDouble()
        try await repository.record(.current)
        let configuration = try config()
        let authorization = AuthorizeExternalAIOperation(repository: repository, scope: configuration.scope)
        let data = try envelope(content: proposals)
        IdentificationURLProtocol.handler = { _ in (200, data) }
        let client = try adapter(configuration)
        let blocked = try await authorization.execute {
            XCTFail("Old acceptance allowed HTTP")
            return try await client.identify(photo: self.photo)
        }
        guard case .requiresConfirmation = blocked else { return XCTFail() }
        XCTAssertEqual(IdentificationURLProtocol.requests, 0)
        // Dismissing a notice never invokes execute(confirmed: true).
        let old = await repository.value; XCTAssertEqual(old, .current)
        for confirmed in [true, false] {
            let result = try await authorization.execute(confirmed: confirmed) {
                let saved = await repository.value
                XCTAssertEqual(saved, configuration.scope) // Persistence before transport.
                return try await client.identify(photo: self.photo)
            }
            guard case .completed = result else { return XCTFail() }
        }
        XCTAssertEqual(IdentificationURLProtocol.requests, 2)
    }

    func testConfigurationFailClosedAndCanonicalScope() throws {
        let original = try config()
        let normalized = try IdentificationAPIConfiguration(baseURL: "https://INFERENCE.devexpert.io:443/v1/", model: "chat", key: "rotated-key", timeout: "120")
        XCTAssertEqual(original.scope, normalized.scope)
        XCTAssertEqual(original.endpoint, normalized.endpoint)
        XCTAssertNotEqual(original.scope, .current)
        let changed = try IdentificationAPIConfiguration(baseURL: "https://other.invalid/v2", model: "another/vision-model", key: nil)
        XCTAssertNotEqual(changed.scope, original.scope)
        XCTAssertEqual(original.scope.noticeVersion, 5)
        XCTAssertEqual(changed.notice.destination, changed.endpoint.absoluteString)
        XCTAssertEqual(changed.notice.model, changed.model)
        for base in ["http://inference.devexpert.io/v1", "https://inference.devexpert.io:0/v1", "https://inference.devexpert.io:65536/v1", "https://inference.devexpert.io/v1/chat/completions", "https://inference.devexpert.io/v1/chat/completions/", "https://inference.devexpert.io/v1?x=1", "https://user@inference.devexpert.io/v1", "https://inference.devexpert.io/v1/../v1", "https://inference.devexpert.io/v1%2f", "https://inference.devexpert.io//v1", "https://inference.devexpert.io/v1#x", "https://inference.devexpert.io\\other/v1", "https://inference.devexpert.io/v1 ", "https://"] {
            XCTAssertThrowsError(try IdentificationAPIConfiguration(baseURL: base, model: "chat", key: "synthetic-key"))
        }
        for key in [" synthetic-key", "synthetic-key\n", "your-key", "$(KEY)"] { XCTAssertThrowsError(try config(key: key)) }
        for model in ["", " ", " model", "model\n", "$(MODEL)", String(repeating: "a", count: 161)] {
            XCTAssertThrowsError(try IdentificationAPIConfiguration(baseURL: "https://other.invalid/v1", model: model, key: nil))
        }
        for base in ["https://other.invalid", "https://other.invalid/", "https://other.invalid/v2", "https://other.invalid:8443/custom/api"] {
            let generic = try IdentificationAPIConfiguration(baseURL: base, model: "arbitrary/vision-model", key: nil)
            XCTAssertTrue(generic.endpoint.absoluteString.hasSuffix("/chat/completions"))
            XCTAssertNil(generic.key)
        }
        for timeout in ["9", "121", "nan", "abc"] { XCTAssertThrowsError(try IdentificationAPIConfiguration(baseURL: "https://inference.devexpert.io/v1", model: "chat", key: "synthetic-key", timeout: timeout)) }
        XCTAssertEqual(IdentificationURLProtocol.requests, 0)
        let specialKey = "synthetic+//=.$#()_\"-$(literal)-end"
        XCTAssertEqual(try config(key: specialKey).key, specialKey)
    }

    func testSplitSchemeHostPathBuildsExactURLWithoutChangingConsentOrAuth() throws {
        let split = try IdentificationAPIConfiguration(scheme: "https", hostPath: "inference.devexpert.io/v1", model: "chat", key: "synthetic-key")
        let direct = try config()
        XCTAssertEqual(split.endpoint.absoluteString, "https://inference.devexpert.io/v1/chat/completions")
        XCTAssertEqual(split.scope, direct.scope)
        let canonical = try IdentificationAPIConfiguration(scheme: "https", hostPath: "INFERENCE.devexpert.io:443/v1/", model: "chat", key: "rotated-key")
        XCTAssertEqual(canonical.scope, split.scope)
        XCTAssertEqual(canonical.endpoint, split.endpoint)
        for scheme in ["http", "https:", "HTTPS", " https", "https ", ""] {
            XCTAssertThrowsError(try IdentificationAPIConfiguration(scheme: scheme, hostPath: "inference.devexpert.io/v1", model: "chat", key: "synthetic-key"))
        }
        for hostPath in ["", "/inference.devexpert.io/v1", "https://inference.devexpert.io/v1", "user@inference.devexpert.io/v1", "inference.devexpert.io/v1?x=1", "inference.devexpert.io/v1#x", "inference.devexpert.io/v1/../v1", "inference.devexpert.io/v1%2f", "inference.devexpert.io//v1", "inference.devexpert.io/v1/chat/completions", "inference.devexpert.io/v1 "] {
            XCTAssertThrowsError(try IdentificationAPIConfiguration(scheme: "https", hostPath: hostPath, model: "chat", key: "synthetic-key"))
        }
        let anotherModel = try IdentificationAPIConfiguration(scheme: "https", hostPath: "inference.devexpert.io/v1", model: "chat-pro", key: nil)
        XCTAssertNotEqual(anotherModel.scope, split.scope)
        for key in [nil, "", " "] as [String?] {
            let anonymous = try IdentificationAPIConfiguration(scheme: "https", hostPath: "inference.devexpert.io/v1", model: "chat", key: key)
            XCTAssertNil(anonymous.key)
            XCTAssertEqual(anonymous.scope, split.scope)
        }
        let anonymous = try IdentificationAPIConfiguration(scheme: "https", hostPath: "arbitrary.invalid:8443/custom", model: "vision", key: nil)
        XCTAssertNil(anonymous.key)
        XCTAssertNotEqual(anonymous.scope, split.scope)
        XCTAssertEqual(IdentificationURLProtocol.requests, 0)
    }

    func testRuntimeSplitConfigurationComesFromBundleNotDefaults() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("bundle")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let info: [String: Any] = ["CFBundleIdentifier": "org.plantcareai.synthetic-config", "PlantCareAIAPIScheme": "https", "PlantCareAIAPIHostPath": "inference.devexpert.io/v1", "PlantCareAIModel": "chat", "PlantCareAIAPIKey": "synthetic-key", "PlantCareAITimeoutSeconds": "60"]
        let bytes = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try bytes.write(to: root.appendingPathComponent("Info.plist"))
        let bundle = try XCTUnwrap(Bundle(url: root))
        let configuration = try XCTUnwrap(IdentificationAPIConfiguration.localDemo(bundle: bundle))
        XCTAssertEqual(configuration.endpoint.absoluteString, "https://inference.devexpert.io/v1/chat/completions")
        XCTAssertEqual(configuration.scope, try config().scope)
        XCTAssertEqual(configuration.key, "synthetic-key")
        // The key comes from a synthetic bundle only; no real configuration is inspected.
    }

    func testArbitraryCompatibleEndpointWithoutKeyOmitsAuthorizationAndHasDifferentScope() async throws {
        let configuration = try IdentificationAPIConfiguration(baseURL: "https://arbitrary.invalid:8443/custom/api", model: "vision/vendor-alias", key: nil)
        XCTAssertNotEqual(configuration.scope, try config().scope)
        let data = try envelope(content: proposals)
        IdentificationURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://arbitrary.invalid:8443/custom/api/chat/completions")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (200, data)
        }
        _ = try await adapter(configuration).identify(photo: photo)
        XCTAssertEqual(IdentificationURLProtocol.requests, 1)
    }

    func testChangedHostPathPortModelRenewsConsentAndNeverInheritsDevExpertV2() async throws {
        let first = try config()
        let repository = ConsentDouble()
        try await repository.record(ExternalAIConsent(recipient: "devexpert:retired-profile-fingerprint", noticeVersion: 2))
        let data = try envelope(content: proposals)
        IdentificationURLProtocol.handler = { _ in (200, data) }
        let variants = [first,
            try IdentificationAPIConfiguration(baseURL: "https://second.invalid/v1", model: "chat", key: nil),
            try IdentificationAPIConfiguration(baseURL: "https://second.invalid/v2", model: "chat", key: nil),
            try IdentificationAPIConfiguration(baseURL: "https://second.invalid:8443/v2", model: "chat", key: nil),
            try IdentificationAPIConfiguration(baseURL: "https://second.invalid:8443/v2", model: "vision-b", key: nil)]
        for (index, configuration) in variants.enumerated() {
            let authorization = AuthorizeExternalAIOperation(repository: repository, scope: configuration.scope)
            let client = try adapter(configuration)
            let blocked = try await authorization.execute { XCTFail("Old acceptance invoked transport"); return try await client.identify(photo: self.photo) }
            guard case .requiresConfirmation = blocked else { return XCTFail() }
            XCTAssertEqual(IdentificationURLProtocol.requests, index)
            _ = try await authorization.execute(confirmed: true) {
                let saved = await repository.value; XCTAssertEqual(saved, configuration.scope)
                return try await client.identify(photo: self.photo)
            }
            XCTAssertEqual(IdentificationURLProtocol.requests, index + 1)
        }
    }

    func testUnauthorizedResponseDoesNotRetryWithOrWithoutAuthentication() async throws {
        for key in [nil, "", "synthetic-key"] as [String?] {
            IdentificationURLProtocol.requests = 0
            let configuration = try IdentificationAPIConfiguration(baseURL: "https://arbitrary.invalid/v1", model: "arbitrary-model", key: key)
            IdentificationURLProtocol.handler = { request in
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), key == "synthetic-key" ? "Bearer synthetic-key" : nil)
                return (401, Data())
            }
            do { _ = try await adapter(configuration).identify(photo: photo); XCTFail() }
            catch { XCTAssertEqual(error as? SpeciesIdentificationError, .unauthorized) }
            XCTAssertEqual(IdentificationURLProtocol.requests, 1)
        }
    }

    func testStatusesNetworkTimeoutAndInvalidResponsesDoNotRetry() async throws {
        let cases: [(Int, Data, SpeciesIdentificationError)] = [
            (401, Data(), .unauthorized), (403, Data(), .unauthorized), (429, Data(), .rateLimited), (500, Data(), .service),
            (302, Data(), .service), (400, Data(), .rejected), (200, Data("not json".utf8), .invalidResponse),
            (200, try envelope(content: proposals, finish: "length"), .rejected),
            (200, try envelope(content: proposals, refusal: "Cannot identify"), .rejected),
            (200, try envelope(content: "{}"), .invalidResponse),
            (200, Data(repeating: 65, count: 1024 * 1024 + 1), .invalidResponse)
        ]
        for (status, data, expected) in cases {
            IdentificationURLProtocol.requests = 0
            IdentificationURLProtocol.handler = { _ in (status, data) }
            do { _ = try await adapter().identify(photo: photo); XCTFail("Unexpected success") }
            catch { XCTAssertEqual(error as? SpeciesIdentificationError, expected) }
            XCTAssertEqual(IdentificationURLProtocol.requests, 1)
        }
        for (code, expected) in [(URLError.Code.notConnectedToInternet, SpeciesIdentificationError.network), (.timedOut, .timeout)] {
            IdentificationURLProtocol.handler = { _ in throw URLError(code) }
            do { _ = try await adapter().identify(photo: photo); XCTFail() } catch { XCTAssertEqual(error as? SpeciesIdentificationError, expected) }
        }
    }

    func testInsufficientEvidenceIsValidNotServiceFailure() async throws {
        let data = try envelope(content: #"{"outcome":"insufficientEvidence","primary":null,"alternatives":[],"uncertainty":"La foto no muestra rasgos suficientes."}"#)
        IdentificationURLProtocol.handler = { _ in (200, data) }
        let result = try await adapter().identify(photo: photo)
        XCTAssertEqual(result.outcome, .insufficientEvidence); XCTAssertNil(result.primary)
    }

    func testCancellationPropagatesToTransportAndTotalDeadline() async throws {
        IdentificationURLProtocol.hold = true
        let repository = try adapter()
        let task = Task { try await repository.identify(photo: photo) }
        for _ in 0..<200 where IdentificationURLProtocol.requests == 0 { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertEqual(IdentificationURLProtocol.requests, 1)
        task.cancel()
        do { _ = try await task.value; XCTFail() } catch { XCTAssertTrue(error is CancellationError) }
        for _ in 0..<200 where !IdentificationURLProtocol.stopped { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertTrue(IdentificationURLProtocol.stopped)

        let short = try IdentificationAPIConfiguration(baseURL: "https://inference.devexpert.io/v1", model: "chat", key: "synthetic-key", timeout: "10")
        let start = Date()
        do { _ = try await adapter(short).identify(photo: photo); XCTFail() } catch { XCTAssertEqual(error as? SpeciesIdentificationError, .timeout) }
        XCTAssertLessThan(Date().timeIntervalSince(start), 15)
    }

    func testDelegateRejectsEveryRedirectIncludingSameHost() throws {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let original = try config().endpoint
        let task = session.dataTask(with: original)
        let response = HTTPURLResponse(url: original, statusCode: 302, httpVersion: nil, headerFields: nil)!
        for url in ["https://inference.devexpert.io/v1/other", "https://other.invalid/v1/chat/completions"] {
            var invoked = false
            IdentificationSessionDelegate().urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: URLRequest(url: URL(string: url)!)) { request in
                invoked = true; XCTAssertNil(request)
            }
            XCTAssertTrue(invoked)
        }
    }
}
