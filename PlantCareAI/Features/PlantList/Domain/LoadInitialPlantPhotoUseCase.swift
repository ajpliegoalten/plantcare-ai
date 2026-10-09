import Foundation

struct LoadInitialPlantPhoto: Sendable {
    let repository: any PlantRepository
    func execute(for id: UUID) async throws -> Data {
        try await repository.loadInitialPhoto(for: id)
    }
}
