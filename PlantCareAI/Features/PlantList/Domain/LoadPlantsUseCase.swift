protocol LoadPlantsUseCase {
    func execute() -> [Plant]
}

struct LoadPlants: LoadPlantsUseCase {
    let repository: any PlantRepository

    func execute() -> [Plant] {
        repository.loadPlants()
    }
}
