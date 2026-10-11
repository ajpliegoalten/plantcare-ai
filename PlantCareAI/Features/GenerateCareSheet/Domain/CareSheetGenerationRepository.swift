import Foundation

protocol CareSheetGenerationRepository: Sendable {
    func generate(identity: ConfirmedDraftIdentity) async throws -> CareSheet
}

enum CareSheetGenerationError: Error, Equatable, Sendable {
    case configuration, invalidInput, network, timeout, unauthorized, rateLimited, service, rejected, invalidResponse
}
