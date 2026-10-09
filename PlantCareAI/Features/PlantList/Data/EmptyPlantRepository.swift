// Temporary adapter: replace with local persistence in local-plant-storage.
struct EmptyPlantRepository: PlantRepository {
    func loadPlants() -> [Plant] {
        []
    }
}
