import Foundation

struct ExternalAIConsent: Equatable, Sendable {
    let recipient: String
    let noticeVersion: Int
    // Provisional scope only. A real provider requires a new recipient and notice.
    static let current = ExternalAIConsent(recipient: "prototype-external-ai", noticeVersion: 1)
}

/// Presentation data from the same immutable destination snapshot as authorization/transport.
/// An endpoint/model is not a verified company identity or a retention guarantee.
struct ExternalAIDestinationNotice: Equatable, Sendable {
    let destination: String
    let model: String
}

enum ExternalAIAuthorizationResult<Value> {
    case requiresConfirmation
    case completed(Value)
}
