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
        #if DEBUG && targetEnvironment(simulator)
        var candidatesFixture: IdentificationCandidatesTestFixture?
        if let position = arguments.firstIndex(of: "--identification-candidates-fixture"), arguments.indices.contains(position + 1) {
            candidatesFixture = IdentificationCandidatesTestFixture(mode: arguments[position + 1])
        }
        #endif
        viewModel.makeIdentificationPhoto = {
            // Snapshot once per draft; recheck the same configuration before acceptance and transport.
            let configuration = IdentificationAPIConfiguration.localDemo()
            var scope = configuration?.scope ?? ExternalAIConsent(recipient: "unconfigured-identification", noticeVersion: 3)
            var destinationNotice = configuration?.notice
            var available = configuration != nil
            var realRecipient = true
            #if DEBUG && targetEnvironment(simulator)
            if consentFixture != nil {
                scope = .current; available = true; realRecipient = false; destinationNotice = nil
            } else if candidatesFixture != nil {
                let second = arguments.contains("--identification-second-destination")
                let fixtureConfiguration = try! IdentificationAPIConfiguration(
                    baseURL: second ? "https://vision-two.invalid/api" : "https://vision-one.invalid/v1",
                    model: second ? "vision-test-b" : "vision-test-a", key: nil)
                scope = fixtureConfiguration.scope
                destinationNotice = fixtureConfiguration.notice
                available = true
            }
            // Tests that explicitly exercise absent configuration must be deterministic even with a demo key.
            if arguments.contains("--identification-no-configuration") { available = false }
            #endif
            let authorization = AuthorizeExternalAIOperation(repository: consentRepository, scope: scope)
            let identify = configuration.map { IdentifyCandidates(repository: OpenAICompatibleSpeciesIdentificationRepository(configuration: $0)) }
            let draft = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), camera: CheckCameraAccess(access: SystemCameraAccess()), authorize: authorization, confirmSpecies: ConfirmSpecies(), usesRealRecipient: realRecipient, destinationNotice: destinationNotice, identificationAvailable: available, configurationIsCurrent: {
                #if DEBUG && targetEnvironment(simulator)
                if consentFixture != nil || candidatesFixture != nil { return true }
                #endif
                return configuration == IdentificationAPIConfiguration.localDemo()
            }, identify: { photo in
                #if DEBUG && targetEnvironment(simulator)
                if let consentFixture { return consentFixture.invoke() }
                if let candidatesFixture { return try await candidatesFixture.identify(photo) }
                #endif
                guard let identify else { return .unavailable }
                return .completed(try await identify.execute(photo: photo))
            })
            #if DEBUG && targetEnvironment(simulator)
            if let consentFixture {
                draft.testInvocationCount = { consentFixture.invocations }
            }
            if let candidatesFixture { draft.testInvocationCount = { candidatesFixture.invocations } }
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
