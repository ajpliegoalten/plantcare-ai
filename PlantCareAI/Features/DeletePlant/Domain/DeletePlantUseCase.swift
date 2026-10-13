import Foundation

protocol DeletePlantUseCase: Sendable {
    func execute(_ expected: Plant) async throws -> Plant
}

struct DeletePlant: DeletePlantUseCase {
    let repository: any PlantDeletingRepository
    func execute(_ expected: Plant) async throws -> Plant {
        try await repository.deletePlant(expected)
    }
}
