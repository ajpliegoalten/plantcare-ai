import Foundation

protocol IdentificationPhotoPreparing: Sendable {
    func prepare(_ data: Data) async throws -> IdentificationPhoto
}

struct PrepareIdentificationPhoto: Sendable {
    let preparer: any IdentificationPhotoPreparing

    func execute(_ data: Data) async throws -> IdentificationPhoto {
        try Task.checkCancellation()
        let photo = try await preparer.prepare(data)
        try Task.checkCancellation()
        return photo
    }
}
