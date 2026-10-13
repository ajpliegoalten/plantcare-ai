import Foundation

protocol PlantPhotoDeletingRepository: Sendable {
    func deletePhoto(_ expected: PlantPhoto) async throws -> PlantPhoto
}

protocol PlantPhotoRepository: Sendable {
    func savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto
    func loadPhotos(for plantID: UUID) async throws -> [PlantPhoto]
    func loadPhoto(id: UUID, for plantID: UUID) async throws -> Data
}
