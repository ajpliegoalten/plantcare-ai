import Foundation

@MainActor
final class PlantListViewModel: ObservableObject {
    enum State { case loading, loaded([Plant]), failed }
    @Published private(set) var state: State = .loading
    private let loadPlants: any LoadPlantsUseCase
    private let loadPhoto: LoadInitialPlantPhoto
    @Published private(set) var cards: [PlantCardViewModel] = []
    private var hasLoaded = false

    init(loadPlants: any LoadPlantsUseCase, loadPhoto: LoadInitialPlantPhoto) {
        self.loadPlants = loadPlants
        self.loadPhoto = loadPhoto
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        state = .loading
        do {
            let plants = try await loadPlants.execute()
            cards = plants.map { PlantCardViewModel(plant: $0, loadPhoto: loadPhoto) }
            state = .loaded(plants)
        }
        catch { state = .failed }
    }

    func selectedPlant(id: UUID) -> Plant? {
        cards.first { $0.id == id }?.plant
    }
}
