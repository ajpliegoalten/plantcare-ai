#if DEBUG && targetEnvironment(simulator)
import Foundation

@MainActor
final class ExternalAIConsentTestFixture {
    var invocations = 0
    func invoke() -> IdentificationContinuationResult {
        invocations += 1
        return .unavailable
    }
}

actor FailingExternalAIConsentTestRepository: ExternalAIConsentRepository {
    func acceptance() async throws -> ExternalAIConsent? { throw CocoaError(.fileReadUnknown) }
    func record(_ consent: ExternalAIConsent) async throws { throw CocoaError(.fileWriteUnknown) }
}
#endif
