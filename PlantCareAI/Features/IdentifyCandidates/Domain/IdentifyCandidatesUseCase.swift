import Foundation

struct IdentifyCandidates: Sendable {
    let repository: any SpeciesIdentificationRepository

    func execute(photo: IdentificationPhoto) async throws -> IdentificationResult {
        try Task.checkCancellation()
        guard !photo.jpeg.isEmpty, photo.jpeg.count <= 5 * 1024 * 1024, photo.width > 0, photo.height > 0 else {
            throw SpeciesIdentificationError.invalidResponse
        }
        let result = try await repository.identify(photo: photo)
        try Task.checkCancellation()
        return try result.validated()
    }
}
