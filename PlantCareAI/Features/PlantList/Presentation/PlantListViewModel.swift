import Foundation
import UIKit

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
    private let registerCare: RegisterCareEvent?
    private let loadLastWatering: (any LoadLastWateringUseCase)?
    private var metadataGeneration = 0
    @Published private(set) var newlyAddedPlantID: UUID?
    @Published private(set) var deletionEvent: UUID?
    var deletePlant: (any DeletePlantUseCase)?
    #if DEBUG && targetEnvironment(simulator)
    var lastCareInvocationCount: Int?
    var lastIdentificationInvocationCount: Int?
    #endif
    var makeIdentificationPhoto: (() -> IdentificationPhotoViewModel)?
    var makeAddPhoto: ((Plant, @escaping @MainActor (PlantPhoto, UIImage) -> Void) -> AddPlantPhotoViewModel)?
    var makePhotoPager: ((Plant) -> PlantPhotoPagerViewModel)?
    var makeTimeline: ((UUID) -> PlantTimelineViewModel)?
    var makeAnalysis: ((UUID, PlantPhotoIdentity) -> PlantPhotoAnalysisViewModel?)?
    var makeQuestion: ((Plant, UIImage?) -> PlantQuestionViewModel?)?
    private var details: [UUID: WeakDetail] = [:]
    private final class WeakDetail {
        weak var value: PlantDetailViewModel?
        init(_ value: PlantDetailViewModel) { self.value = value }
    }

    init(loadPlants: any LoadPlantsUseCase, loadPhoto: LoadInitialPlantPhoto, loadDetail: LoadPlantDetail, update: UpdatePlant, registerCare: RegisterCareEvent? = nil, loadLastWatering: (any LoadLastWateringUseCase)? = nil) {
        self.loadPlants = loadPlants
        self.loadPhoto = loadPhoto
        self.loadDetail = loadDetail
        self.update = update
        self.registerCare = registerCare
        self.loadLastWatering = loadLastWatering
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        state = .loading
        let request = metadataGeneration
        do {
            let plants = try await loadPlants.execute()
            guard request == metadataGeneration else { return }
            let retained = Dictionary(cards.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            cards = plants.map { plant in
                if let card = retained[plant.id] {
                    if card.plant != plant { card.applyUpdatedPlant(plant) }
                    return card
                }
                return PlantCardViewModel(plant: plant, loadPhoto: loadPhoto, loadLastWatering: loadLastWatering)
            }
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
            let card = PlantCardViewModel(plant: plant, loadPhoto: loadPhoto, loadLastWatering: loadLastWatering)
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
        if let retained = details[id]?.value { return retained }
        let detail = PlantDetailViewModel(id: id, loadDetail: loadDetail, loadPhoto: loadPhoto, update: update, registerCare: registerCare, loadLastWatering: loadLastWatering, onWatering: { [weak self] id in
            self?.cards.first { $0.id == id }?.lastWatering.invalidate()
        }) { [weak self] plant in
            self?.applyUpdatedPlant(plant)
        }
        detail.makeAddPhoto = makeAddPhoto
        detail.makePhotoPager = makePhotoPager
        detail.makeAnalysis = makeAnalysis
        detail.makeQuestion = makeQuestion
        detail.deletePlant = deletePlant
        detail.onDeleted = { [weak self] plant in self?.applyDeletedPlant(plant) }
        details[id] = WeakDetail(detail)
        return detail
    }

    func applyDeletedPlant(_ plant: Plant) {
        metadataGeneration += 1
        cards.first { $0.id == plant.id }?.invalidateDeletedPlant()
        cards.removeAll { $0.id == plant.id }
        details[plant.id]?.value?.invalidateDeletedPlant(); details[plant.id] = nil
        if newlyAddedPlantID == plant.id { newlyAddedPlantID = nil }
        deletionEvent = UUID()
        if case .loaded(let plants) = state {
            state = .loaded(plants.filter { $0.id != plant.id })
        } else {
            hasLoaded = false
            Task { await load() }
        }
    }

    func applyHistoryDeletion(_ entry: PlantTimelineEntry) {
        details[entry.plantID]?.value?.applyHistoryDeletion(entry)
        if case .care(let event) = entry, event.kind == .watering {
            cards.first { $0.id == entry.plantID }?.lastWatering.invalidate()
        }
    }

    func analysisSaved(_ record: SavedPlantPhotoAnalysis) {
        details[record.plantID]?.value?.analysisSaved(record)
    }

    func applyUpdatedPlant(_ plant: Plant) {
        guard case .loaded(let plants) = state, plants.contains(where: { $0.id == plant.id }) else { return }
        metadataGeneration += 1
        cards.first { $0.id == plant.id }?.applyUpdatedPlant(plant)
        state = .loaded(plants.map { $0.id == plant.id ? plant : $0 })
    }
}
