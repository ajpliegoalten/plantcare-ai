import Foundation

@MainActor
final class PlantListViewModel: ObservableObject {
    enum State { case loading, loaded([Plant]), failed }
    @Published private(set) var state: State = .loading
    private let loadPlants: any LoadPlantsUseCase
    private let loadPhoto: LoadInitialPlantPhoto
    private let loadDetail: LoadPlantDetail
    @Published private(set) var cards: [PlantCardViewModel] = []
    private var hasLoaded = false
    private let update: UpdatePlant
    private var metadataGeneration = 0

    init(loadPlants: any LoadPlantsUseCase, loadPhoto: LoadInitialPlantPhoto, loadDetail: LoadPlantDetail, update: UpdatePlant) {
        self.loadPlants = loadPlants
        self.loadPhoto = loadPhoto
        self.loadDetail = loadDetail
        self.update = update
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        state = .loading
        let request = metadataGeneration
        do {
            let plants = try await loadPlants.execute()
            guard request == metadataGeneration else { return }
            cards = plants.map { PlantCardViewModel(plant: $0, loadPhoto: loadPhoto) }
            state = .loaded(plants)
        }
        catch { if request == metadataGeneration { state = .failed } }
    }

    func selectedPlant(id: UUID) -> Plant? {
        cards.first { $0.id == id }?.plant
    }

    func detailViewModel(id: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(id: id, loadDetail: loadDetail, loadPhoto: loadPhoto, update: update) { [weak self] plant in
            self?.applyUpdatedPlant(plant)
        }
    }

    func applyUpdatedPlant(_ plant: Plant) {
        guard case .loaded(let plants) = state, plants.contains(where: { $0.id == plant.id }) else { return }
        metadataGeneration += 1
        cards.first { $0.id == plant.id }?.applyUpdatedPlant(plant)
        state = .loaded(plants.map { $0.id == plant.id ? plant : $0 })
    }
}
