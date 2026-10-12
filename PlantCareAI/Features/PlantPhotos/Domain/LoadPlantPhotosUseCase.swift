import Foundation

struct LoadPlantPhotos {
    let repository: any PlantPhotoRepository
    func execute(for plantID: UUID) async throws -> [PlantPhoto] {
        try await repository.loadPhotos(for: plantID)
    }
}
