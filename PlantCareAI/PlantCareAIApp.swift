import SwiftUI

@main
struct PlantCareAIApp: App {
    @StateObject private var plantListViewModel = PlantListViewModel(
        loadPlants: LoadPlants(repository: EmptyPlantRepository())
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: plantListViewModel)
        }
    }
}
