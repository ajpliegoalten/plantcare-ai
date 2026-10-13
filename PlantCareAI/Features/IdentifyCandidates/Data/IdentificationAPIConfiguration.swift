import Foundation
import CryptoKit

/// One Chat Completions transport; configuration is not a declaration of provider identity.
struct IdentificationAPIConfiguration: Equatable, Sendable {
    let endpoint: URL
    let model: String
    let key: String?
    let timeout: TimeInterval
    let scope: ExternalAIConsent
    let notice: ExternalAIDestinationNotice

    init(scheme: String, hostPath: String, model: String, key: String?, timeout: String? = nil) throws {
        guard scheme == "https", !hostPath.isEmpty, !hostPath.hasPrefix("/"),
              !hostPath.contains("://"), !hostPath.contains("//"),
              hostPath == hostPath.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw SpeciesIdentificationError.configuration
        }
        try self.init(baseURL: scheme + "://" + hostPath, model: model, key: key, timeout: timeout)
    }

    init(baseURL: String, model: String, key: String?, timeout: String? = nil) throws {
        guard baseURL.count <= 2048,
              !baseURL.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.union(.controlCharacters).contains($0) }),
              let components = URLComponents(string: baseURL), components.scheme == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              components.port.map({ (1...65535).contains($0) }) ?? true,
              !(components.percentEncodedHost?.contains("%") ?? true),
              !components.percentEncodedPath.contains("%"), !components.path.contains("//"),
              !components.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
              !model.isEmpty, model.count <= 160,
              model == model.trimmingCharacters(in: .whitespacesAndNewlines),
              !model.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              !model.hasPrefix("$(") else {
            throw SpeciesIdentificationError.configuration
        }
        var normalized = components
        normalized.host = host.lowercased()
        if normalized.port == 443 { normalized.port = nil }
        if normalized.path.hasSuffix("/") { normalized.path.removeLast() }
        guard !normalized.path.lowercased().hasSuffix("/chat/completions"),
              let canonical = normalized.string else { throw SpeciesIdentificationError.configuration }
        let supplied = key ?? ""
        let absent = supplied.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !absent {
            guard supplied == supplied.trimmingCharacters(in: .whitespacesAndNewlines),
                  supplied.unicodeScalars.allSatisfy({ $0.value >= 33 && $0.value <= 126 }),
                  !supplied.hasPrefix("$("),
                  !["placeholder", "your-key", "your_api_key", "replace-me", "example-key", "<key>", "<api_key>"].contains(supplied.lowercased()) else {
                throw SpeciesIdentificationError.configuration
            }
        }
        let seconds = (timeout == nil || timeout == "") ? 60 : Double(timeout!)
        guard let seconds, seconds.isFinite, (10...120).contains(seconds) else { throw SpeciesIdentificationError.configuration }
        normalized.path += "/chat/completions"
        guard let endpoint = normalized.url else { throw SpeciesIdentificationError.configuration }
        self.endpoint = endpoint
        self.model = model
        self.key = absent ? nil : supplied
        self.timeout = seconds
        self.notice = ExternalAIDestinationNotice(destination: endpoint.absoluteString, model: model)
        // Canonical destination + model + notice revision. No assumed vendor/processors, key or timeout.
        // v5 adds selected-photo analysis with prior textual context; never inherits v4.
        let scopeBytes = try JSONEncoder().encode([canonical, endpoint.absoluteString, model, "openai-compatible-identification:notice-5"])
        let fingerprint = SHA256.hash(data: scopeBytes).map { String(format: "%02x", $0) }.joined()
        self.scope = ExternalAIConsent(recipient: "openai-compatible:" + fingerprint, noticeVersion: 5)
    }

    static func localDemo(bundle: Bundle = .main) -> Self? {
        #if DEBUG
        guard let scheme = bundle.object(forInfoDictionaryKey: "PlantCareAIAPIScheme") as? String,
              let hostPath = bundle.object(forInfoDictionaryKey: "PlantCareAIAPIHostPath") as? String,
              let model = bundle.object(forInfoDictionaryKey: "PlantCareAIModel") as? String else { return nil }
        return try? Self(scheme: scheme, hostPath: hostPath, model: model,
                         key: bundle.object(forInfoDictionaryKey: "PlantCareAIAPIKey") as? String,
                         timeout: bundle.object(forInfoDictionaryKey: "PlantCareAITimeoutSeconds") as? String)
        #else
        return nil
        #endif
    }
}
