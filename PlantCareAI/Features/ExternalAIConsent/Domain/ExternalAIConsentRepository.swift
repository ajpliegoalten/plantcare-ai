import Foundation

protocol ExternalAIConsentRepository: Sendable {
    func acceptance() async throws -> ExternalAIConsent?
    func record(_ consent: ExternalAIConsent) async throws
}
