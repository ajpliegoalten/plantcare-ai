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
        // Batch cleanup only accepts UUID-scoped test namespaces, never PlantStore
        // or standard preferences. One cleanup launch suffices for every scenario.
        if let position = arguments.firstIndex(of: "--test-cleanup-ids"),
           arguments.indices.contains(position + 1) {
            for value in arguments[position + 1].split(separator: ",") {
                guard let id = UUID(uuidString: String(value)) else { continue }
                let testRoot = URL.applicationSupportDirectory.appendingPathComponent("StorageTests").appendingPathComponent(id.uuidString)
                try? FileManager.default.removeItem(at: testRoot)
                let suite = "ExternalAIConsentTests.\(id.uuidString)"
                UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
            }
        }
        if let position = arguments.firstIndex(of: "--storage-test-id"),
           arguments.indices.contains(position + 1), let id = UUID(uuidString: arguments[position + 1]) {
            let testRoot = URL.applicationSupportDirectory.appendingPathComponent("StorageTests").appendingPathComponent(id.uuidString)
            repository = LocalPlantRepository(root: testRoot)
            if let position = arguments.firstIndex(of: "--care-fixture"), arguments.indices.contains(position + 1) {
                let fixture = CareEventTestFixture(root: testRoot, mode: arguments[position + 1])
                repository = LocalPlantRepository(root: testRoot, beforeCareCommit: { try fixture.beforeCareCommit($0) })
            }
            if let position = arguments.firstIndex(of: "--plant-creation-fixture"), arguments.indices.contains(position + 1) {
                let fixture = PlantCreationTestFixture(mode: arguments[position + 1])
                repository = LocalPlantRepository(root: testRoot, beforeCommit: { try fixture.beforeCommit() })
            }
            if let position = arguments.firstIndex(of: "--additional-photo-fixture"), arguments.indices.contains(position + 1) {
                let fixture = PlantPhotoTestFixture(mode: arguments[position + 1])
                repository = LocalPlantRepository(root: testRoot, beforePhotoCommit: { try fixture.beforeCommit($0) })
            }
            if let position = arguments.firstIndex(of: "--deletion-fixture"), arguments.indices.contains(position + 1) {
                let fixture = HistoryDeletionTestFixture(mode: arguments[position + 1])
                repository = LocalPlantRepository(root: testRoot, beforeDeletionCommit: { try fixture.beforeCommit() })
            }
            load = StorageFixtureLoad(root: testRoot, repository: repository, seed: arguments.contains("--storage-seed"), corrupt: arguments.contains("--storage-corrupt"))
            if let position = arguments.firstIndex(of: "--timeline-fixture"), arguments.indices.contains(position + 1) {
                load = PlantTimelineFixtureLoad(base: load, repository: repository,
                    seed: arguments.contains("--storage-seed"), mode: arguments[position + 1])
            }
        }
        #endif
        var lastWatering: any LoadLastWateringUseCase = LoadLastWatering(repository: repository)
        #if DEBUG && targetEnvironment(simulator)
        if let position = arguments.firstIndex(of: "--last-watering-fixture"), arguments.indices.contains(position + 1),
           let idPosition = arguments.firstIndex(of: "--storage-test-id"), arguments.indices.contains(idPosition + 1),
           UUID(uuidString: arguments[idPosition + 1]) != nil {
            lastWatering = LastWateringReadTestFixture(load: lastWatering, mode: arguments[position + 1])
        }
        #endif
        let viewModel = PlantListViewModel(loadPlants: load, loadPhoto: LoadInitialPlantPhoto(repository: repository), loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository), registerCare: RegisterCareEvent(repository: repository), loadLastWatering: lastWatering)
        var photoReader: any PlantPhotoRepository = repository
        #if DEBUG && targetEnvironment(simulator)
        if let position = arguments.firstIndex(of: "--additional-photo-read-fixture"), arguments.indices.contains(position + 1),
           let idPosition = arguments.firstIndex(of: "--storage-test-id"), arguments.indices.contains(idPosition + 1),
           UUID(uuidString: arguments[idPosition + 1]) != nil {
            photoReader = PlantPhotoReadTestFixture(repository: repository, mode: arguments[position + 1])
        }
        #endif
        viewModel.makePhotoPager = { plant in
            PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: photoReader),
                loadAdditional: LoadPlantPhoto(repository: photoReader), loadInitial: LoadInitialPlantPhoto(repository: repository))
        }
        var timelineReader: any LoadPlantTimelineUseCase = LoadPlantTimeline(
            detail: LoadPlantDetail(repository: repository), care: repository, photos: photoReader)
        #if DEBUG && targetEnvironment(simulator)
        if arguments.contains("--timeline-read-error"),
           let position = arguments.firstIndex(of: "--storage-test-id"), arguments.indices.contains(position + 1),
           UUID(uuidString: arguments[position + 1]) != nil {
            timelineReader = PlantTimelineReadTestFixture(base: timelineReader)
        }
        #endif
        viewModel.makeTimeline = { [weak viewModel] id in
            PlantTimelineViewModel(plantID: id,
                load: timelineReader,
                photos: PlantTimelinePhotoViewModel(plantID: id, loadInitial: LoadInitialPlantPhoto(repository: repository),
                    loadAdditional: LoadPlantPhoto(repository: photoReader)),
                deleteCare: DeleteCareEvent(repository: repository), deletePhoto: DeletePlantPhoto(repository: repository),
                onDeleted: { [weak viewModel] entry in viewModel?.applyHistoryDeletion(entry) })
        }
        viewModel.makeAddPhoto = { plant, onSaved in
            let draft = AddPlantPhotoViewModel(plant: plant, prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()),
                validate: LocalPreparedPlantPhotoValidator(), camera: CheckCameraAccess(access: SystemCameraAccess()),
                add: AddPlantPhoto(repository: repository), onSaved: onSaved)
            #if DEBUG && targetEnvironment(simulator)
            if arguments.contains("--additional-photo-fixture") { draft.testSelections = IdentificationPhotoTestFixture.selections() }
            #endif
            return draft
        }
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
        viewModel.makeIdentificationPhoto = { [weak viewModel] in
            // Snapshot once per draft; recheck the same configuration before acceptance and transport.
            let configuration = IdentificationAPIConfiguration.localDemo()
            var scope = configuration?.scope ?? ExternalAIConsent(recipient: "unconfigured-identification", noticeVersion: 4)
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
            var care = configuration.map { GenerateCareSheet(repository: OpenAICompatibleCareSheetGenerationRepository(configuration: $0)) }
            #if DEBUG && targetEnvironment(simulator)
            var careFixture: CareSheetGenerationTestFixture?
            if candidatesFixture != nil {
                let position = arguments.firstIndex(of: "--care-sheet-fixture")
                let mode = position.flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil } ?? "success"
                let fixture = CareSheetGenerationTestFixture(mode: mode)
                careFixture = fixture
                care = GenerateCareSheet(repository: fixture)
            }
            #endif
            let draft = IdentificationPhotoViewModel(prepare: PrepareIdentificationPhoto(preparer: LocalIdentificationPhotoPreparer()), camera: CheckCameraAccess(access: SystemCameraAccess()), authorize: authorization, confirmSpecies: ConfirmSpecies(), confirmManualSpecies: ConfirmManualSpecies(), generateCare: care, saveConfirmedPlant: SaveConfirmedPlant(repository: repository, photoValidator: LocalPreparedPlantPhotoValidator()), onSaved: { [weak viewModel] plant in
                #if DEBUG && targetEnvironment(simulator)
                viewModel?.lastCareInvocationCount = careFixture?.invocations
                viewModel?.lastIdentificationInvocationCount = candidatesFixture?.invocations
                #endif
                viewModel?.applyCreatedPlant(plant)
            }, usesRealRecipient: realRecipient, destinationNotice: destinationNotice, identificationAvailable: available, configurationIsCurrent: {
                #if DEBUG && targetEnvironment(simulator)
                if consentFixture != nil || candidatesFixture != nil { return true }
                #endif
                return configuration == IdentificationAPIConfiguration.localDemo()
            }, identify: { photo in
                #if DEBUG && targetEnvironment(simulator)
                if let consentFixture { return consentFixture.invoke() }
                if let candidatesFixture {
                    let result = try await candidatesFixture.identify(photo)
                    if arguments.contains("--care-sheet-renew-consent") {
                        try await consentRepository.record(ExternalAIConsent(recipient: scope.recipient, noticeVersion: 3))
                    }
                    return result
                }
                #endif
                guard let identify else { return .unavailable }
                return .completed(try await identify.execute(photo: photo))
            })
            #if DEBUG && targetEnvironment(simulator)
            if let consentFixture {
                draft.testInvocationCount = { consentFixture.invocations }
            }
            if let candidatesFixture { draft.testInvocationCount = { candidatesFixture.invocations } }
            if let careFixture { draft.testCareInvocationCount = { careFixture.invocations } }
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
