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
        var consentRepository: any ExternalAIConsentRepository = UserDefaultsExternalAIConsentRepository(defaults: .standard)
        #if DEBUG && targetEnvironment(simulator)
        var consentFixture: ExternalAIConsentTestFixture?
        if let position = arguments.firstIndex(of: "--consent-test-id"),
           arguments.indices.contains(position + 1), let id = UUID(uuidString: arguments[position + 1]) {
            guard let defaults = UserDefaults(suiteName: "ExternalAIConsentTests.\(id.uuidString)") else {
                preconditionFailure("Could not create isolated consent preferences")
            }
            if arguments.contains("--consent-cleanup") {
                defaults.removePersistentDomain(forName: "ExternalAIConsentTests.\(id.uuidString)")
            }
            consentRepository = UserDefaultsExternalAIConsentRepository(defaults: defaults)
            if arguments.contains("--consent-fail-read") { consentRepository = FailingExternalAIConsentTestRepository() }
            if arguments.contains("--consent-spy") { consentFixture = ExternalAIConsentTestFixture() }
        }
        #endif
        let authorization = AuthorizeExternalAIOperation(repository: consentRepository)
        viewModel.makeIdentificationPhoto = {
            let draft = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), camera: CheckCameraAccess(access: SystemCameraAccess()), authorize: authorization, identify: { _ in
                #if DEBUG && targetEnvironment(simulator)
                if let consentFixture { return consentFixture.invoke() }
                #endif
                // No provider/transport exists until identify-candidates. Never simulate success.
                return .unavailable
            })
            #if DEBUG && targetEnvironment(simulator)
            if let consentFixture {
                draft.testInvocationCount = { consentFixture.invocations }
            }
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
