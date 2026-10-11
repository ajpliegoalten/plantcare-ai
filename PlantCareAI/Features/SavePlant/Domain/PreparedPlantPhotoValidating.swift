import Foundation

protocol PreparedPlantPhotoValidating: Sendable {
    func validate(_ photo: IdentificationPhoto) async throws
}
