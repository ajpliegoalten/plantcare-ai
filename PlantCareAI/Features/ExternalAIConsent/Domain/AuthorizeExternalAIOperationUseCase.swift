import Foundation

struct AuthorizeExternalAIOperation: Sendable {
    let repository: any ExternalAIConsentRepository
    var scope: ExternalAIConsent = .current

    // Does not retain the operation or launch work. Every caller must cross this boundary.
    func execute<Value>(confirmed: Bool = false, operation: () async throws -> Value) async throws -> ExternalAIAuthorizationResult<Value> {
        try Task.checkCancellation()
        let accepted = try await repository.acceptance()
        try Task.checkCancellation()
        if accepted != scope {
            guard confirmed else { return .requiresConfirmation }
            try await repository.record(scope)
            try Task.checkCancellation()
        }
        try Task.checkCancellation()
        return .completed(try await operation())
    }
}
