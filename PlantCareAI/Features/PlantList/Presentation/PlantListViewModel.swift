import Foundation

@MainActor
final class PlantListViewModel: ObservableObject {
    @Published private(set) var plants: [Plant]

    init(loadPlants: any LoadPlantsUseCase) {
        plants = loadPlants.execute()
    }
}
