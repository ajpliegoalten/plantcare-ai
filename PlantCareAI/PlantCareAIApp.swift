import SwiftUI

@main
struct PlantCareAIApp: App {
    @StateObject private var plantListViewModel: PlantListViewModel

    init() {
        let root = URL.applicationSupportDirectory.appendingPathComponent("PlantStore", isDirectory: true)
        var repository = LocalPlantRepository(root: root)
        var load: any LoadPlantsUseCase = LoadPlants(repository: repository)
        #if DEBUG && targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        if let position = arguments.firstIndex(of: "--storage-test-id"),
           arguments.indices.contains(position + 1), let id = UUID(uuidString: arguments[position + 1]) {
            let testRoot = URL.applicationSupportDirectory.appendingPathComponent("StorageTests").appendingPathComponent(id.uuidString)
            repository = LocalPlantRepository(root: testRoot)
            load = StorageFixtureLoad(root: testRoot, repository: repository, seed: arguments.contains("--storage-seed"), corrupt: arguments.contains("--storage-corrupt"))
        }
        #endif
        let viewModel = PlantListViewModel(loadPlants: load, loadPhoto: LoadInitialPlantPhoto(repository: repository), loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository))
        viewModel.makeIdentificationPhoto = {
            let draft = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), camera: CheckCameraAccess(access: SystemCameraAccess()))
            #if DEBUG && targetEnvironment(simulator)
            if arguments.contains("--identification-photo-fixture") {
                draft.testSelections = IdentificationPhotoTestFixture.selections()
            }
            #endif
            return draft
        }
        _plantListViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: plantListViewModel)
        }
    }
}
