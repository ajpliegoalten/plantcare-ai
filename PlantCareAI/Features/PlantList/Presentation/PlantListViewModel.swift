import Foundation

@MainActor
final class PlantListViewModel: ObservableObject {
    enum State { case loading, loaded([Plant]), failed }
    @Published private(set) var state: State = .loading
    private let loadPlants: any LoadPlantsUseCase

    init(loadPlants: any LoadPlantsUseCase) {
        self.loadPlants = loadPlants
    }

    func load() async {
        state = .loading
        do { state = .loaded(try await loadPlants.execute()) }
        catch { state = .failed }
    }
}
