import Foundation

enum PlantStorageError: Error, Equatable {
    case validation
    case duplicateID
    case photoMissing
    case photoCorrupt
    case storage
    case notFound
}

protocol PlantRepository: Sendable {
    func loadPlants() async throws -> [Plant]
    func updatePlant(id: UUID, name: String, location: String?) async throws -> Plant
    func savePlant(_ plant: Plant, initialPhoto: Data) async throws
    func loadInitialPhoto(for id: UUID) async throws -> Data
}
