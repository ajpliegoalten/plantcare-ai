import Foundation

protocol DeletePlantPhotoUseCase: Sendable {
    func execute(_ identity: PlantPhotoIdentity, expected: PlantPhoto) async throws -> PlantPhoto
}

struct DeletePlantPhoto: DeletePlantPhotoUseCase {
    let repository: any PlantPhotoDeletingRepository
    func execute(_ identity: PlantPhotoIdentity, expected: PlantPhoto) async throws -> PlantPhoto {
        guard case .additional(let id) = identity else { throw PlantPhotoError.protectedIdentity }
        guard id == expected.id else { throw PlantPhotoError.conflict }
        return try await repository.deletePhoto(expected)
    }
}
