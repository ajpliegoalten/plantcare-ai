import Foundation

struct LoadPlantPhoto {
    let repository: any PlantPhotoRepository
    func execute(id: UUID, for plantID: UUID) async throws -> Data {
        try await repository.loadPhoto(id: id, for: plantID)
    }
}
