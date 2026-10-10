import Foundation

/// Ephemeral selection, never a persisted plant or a confirmed identity.
struct IdentificationPhoto: Equatable, Sendable {
    let id: UUID
    let jpeg: Data
    let width: Int
    let height: Int
}

enum IdentificationPhotoError: Error, Equatable {
    case empty, unsupported, tooLarge, decodeFailed, transferFailed
}
