import Foundation

protocol SpeciesIdentificationRepository: Sendable {
    func identify(photo: IdentificationPhoto) async throws -> IdentificationResult
}

enum SpeciesIdentificationError: Error, Equatable, Sendable {
    case configuration, network, timeout, unauthorized, rateLimited, service, rejected, invalidResponse
}
