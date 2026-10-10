import Foundation

struct LoadPlantDetail: Sendable {
    let repository: any PlantRepository

    func execute(for id: UUID) async throws -> Plant? {
        try await repository.loadPlants().first { $0.id == id }
    }
}
