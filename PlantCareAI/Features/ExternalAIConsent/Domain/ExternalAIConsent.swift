import Foundation

struct ExternalAIConsent: Equatable, Sendable {
    let recipient: String
    let noticeVersion: Int
    // Provisional scope only. A real provider requires a new recipient and notice.
    static let current = ExternalAIConsent(recipient: "prototype-external-ai", noticeVersion: 1)
}

enum ExternalAIAuthorizationResult<Value> {
    case requiresConfirmation
    case completed(Value)
}

enum IdentificationContinuationResult { case unavailable }
