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
    private let registerWatering: RegisterWatering?
    private var metadataGeneration = 0
    @Published private(set) var newlyAddedPlantID: UUID?
    #if DEBUG && targetEnvironment(simulator)
    var lastCareInvocationCount: Int?
    var lastIdentificationInvocationCount: Int?
    #endif
    var makeIdentificationPhoto: (() -> IdentificationPhotoViewModel)?

    init(loadPlants: any LoadPlantsUseCase, loadPhoto: LoadInitialPlantPhoto, loadDetail: LoadPlantDetail, update: UpdatePlant, registerWatering: RegisterWatering? = nil) {
        self.loadPlants = loadPlants
        self.loadPhoto = loadPhoto
        self.loadDetail = loadDetail
        self.update = update
        self.registerWatering = registerWatering
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

    func applyCreatedPlant(_ plant: Plant) {
        metadataGeneration += 1
        newlyAddedPlantID = plant.id
        if case .loaded(var plants) = state {
            guard !plants.contains(where: { $0.id == plant.id }) else { return }
            plants.append(plant)
            plants.sort { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
            let card = PlantCardViewModel(plant: plant, loadPhoto: loadPhoto)
            cards.append(card)
            cards.sort { $0.plant.createdAt == $1.plant.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.plant.createdAt < $1.plant.createdAt }
            state = .loaded(plants)
        } else {
            hasLoaded = false
            Task { await load() }
        }
    }

    func retryLoad() async {
        metadataGeneration += 1
        hasLoaded = false
        await load()
    }

    func detailViewModel(id: UUID) -> PlantDetailViewModel {
        PlantDetailViewModel(id: id, loadDetail: loadDetail, loadPhoto: loadPhoto, update: update, registerWatering: registerWatering) { [weak self] plant in
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
