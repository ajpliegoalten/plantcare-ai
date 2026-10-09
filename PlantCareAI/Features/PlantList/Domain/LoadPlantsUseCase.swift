protocol LoadPlantsUseCase: Sendable {
    func execute() async throws -> [Plant]
}

struct LoadPlants: LoadPlantsUseCase {
    let repository: any PlantRepository

    func execute() async throws -> [Plant] {
        try await repository.loadPlants()
    }
}
