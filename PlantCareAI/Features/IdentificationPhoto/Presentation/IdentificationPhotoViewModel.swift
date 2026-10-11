import Foundation

struct ManualSpeciesDraft: Identifiable, Equatable {
    let id: UUID
    let photoID: UUID
    var name: String
}

@MainActor
final class IdentificationPhotoViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published private(set) var photo: IdentificationPhoto?
    @Published private(set) var isLoading = false
    @Published private(set) var isCheckingCamera = false
    enum AuthorizationState { case idle, checkingAuthorization, awaitingConfirmation, continuing, failed, unavailable }
    @Published private(set) var authorizationState: AuthorizationState = .idle
    @Published private(set) var identificationResult: IdentificationResult?
    @Published private(set) var identificationError: SpeciesIdentificationError?
    @Published private(set) var resultID: UUID?
    @Published private(set) var selectedProposal: SpeciesProposalSelection?
    @Published private(set) var confirmedIdentity: ConfirmedDraftIdentity?
    @Published private(set) var hasConfirmationError = false
    private var resultPhotoID: UUID?
    private let confirmation: any ConfirmSpeciesUseCase
    private let manualConfirmation: any ConfirmManualSpeciesUseCase
    @Published private(set) var manualDraft: ManualSpeciesDraft?
    private var retainedProposal: SpeciesProposalSelection?
    @Published private(set) var isSelectingSpecies = false
    @Published private(set) var hasManualConfirmationError = false
    var isEditingManualSpecies: Bool { manualDraft != nil }
    var canEnterManualSpecies: Bool { canIdentify && !isEditingManualSpecies }
    var canReturnToAIProposals: Bool {
        !closed && !isBusy && !presentsCamera && !isEditingManualSpecies &&
        confirmedIdentity?.manualName != nil && photo?.id == resultPhotoID &&
        resultID != nil && identificationResult?.outcome == .proposals
    }
    var canSelectProposal: Bool {
        !closed && !isBusy && !presentsCamera && photo != nil && photo?.id == resultPhotoID &&
        resultID != nil && identificationResult?.outcome == .proposals && (confirmedIdentity == nil || isSelectingSpecies)
    }
    var canConfirmSpecies: Bool { canSelectProposal && !isEditingManualSpecies && selectedProposal != nil }
    var canConfirmSelection: Bool {
        if let draft = manualDraft { return validManualSession(draft.id) && !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return canConfirmSpecies
    }

    func confirmSelection() {
        if let draft = manualDraft { confirmManualSpecies(sessionID: draft.id) }
        else if let resultID { confirmSpecies(resultID: resultID) }
    }
    let usesRealRecipient: Bool
    let destinationNotice: ExternalAIDestinationNotice?
    private let configurationIsCurrent: () -> Bool
    private let identificationAvailable: Bool
    var isAuthorizing: Bool { [.checkingAuthorization, .awaitingConfirmation, .continuing].contains(authorizationState) }
    var isBusy: Bool { isLoading || isCheckingCamera || isAuthorizing }
    var canIdentify: Bool { photo != nil && !isBusy && !presentsCamera && !closed && !isEditingManualSpecies }
    private let authorize: AuthorizeExternalAIOperation
    private let identify: (IdentificationPhoto) async throws -> IdentificationContinuationResult
    private var authorizationTask: Task<Void, Never>?
    private var authorizationGeneration = 0
    private var pendingPhotoID: UUID?
    @Published private(set) var error: IdentificationPhotoError?
    @Published private(set) var cameraIssue: CameraAccessResult?
    @Published var presentsCamera = false
    private let prepare: PrepareIdentificationPhoto
    private let camera: CheckCameraAccess
    private var task: Task<Void, Never>?
    private var generation = 0
    private var closed = false
    #if DEBUG && targetEnvironment(simulator)
    var testSelections: [String: Data] = [:]
    var testInvocationCount: (() -> Int)? { didSet { invocationCount = testInvocationCount?() ?? 0 } }
    @Published private(set) var invocationCount = 0
    #endif

    init(prepare: PrepareIdentificationPhoto, camera: CheckCameraAccess, authorize: AuthorizeExternalAIOperation, confirmSpecies: any ConfirmSpeciesUseCase = ConfirmSpecies(), confirmManualSpecies: any ConfirmManualSpeciesUseCase = ConfirmManualSpecies(), usesRealRecipient: Bool = false, destinationNotice: ExternalAIDestinationNotice? = nil, identificationAvailable: Bool = true, configurationIsCurrent: @escaping () -> Bool = { true }, identify: @escaping (IdentificationPhoto) async throws -> IdentificationContinuationResult = { _ in .unavailable }) {
        self.prepare = prepare
        self.camera = camera
        self.authorize = authorize
        self.identify = identify
        self.confirmation = confirmSpecies
        self.manualConfirmation = confirmManualSpecies
        self.usesRealRecipient = usesRealRecipient
        self.destinationNotice = destinationNotice
        self.identificationAvailable = identificationAvailable && (!usesRealRecipient || destinationNotice != nil)
        self.configurationIsCurrent = configurationIsCurrent
    }

    deinit { task?.cancel(); authorizationTask?.cancel() }

    func selectProposal(_ selection: SpeciesProposalSelection, resultID revision: UUID) {
        guard canSelectProposal, revision == resultID, let result = identificationResult else { return }
        switch selection {
        case .primary: guard result.primary != nil else { return }
        case .alternative(let index): guard result.alternatives.indices.contains(index) else { return }
        }
        if let draft = manualDraft { cancelManualSpecies(sessionID: draft.id) }
        isSelectingSpecies = confirmedIdentity != nil
        selectedProposal = selection
        hasConfirmationError = false
    }

    func confirmSpecies(resultID revision: UUID) {
        guard canConfirmSpecies, revision == resultID, let photoID = photo?.id,
              let result = identificationResult, let selectedProposal else { return }
        do {
            confirmedIdentity = try confirmation.execute(photoID: photoID, resultID: revision, result: result, selection: selectedProposal)
            isSelectingSpecies = false
            hasConfirmationError = false
        } catch {
            hasConfirmationError = true
        }
    }

    func changeConfirmedSpecies() {
        guard !closed, !isBusy, !presentsCamera, !isEditingManualSpecies, let identity = confirmedIdentity,
              identity.photoID == photo?.id else { return }
        switch identity.source {
        case .manual: beginManualSpecies()
        case .aiProposal(let revision, _, _, _):
            guard revision == resultID else { return }
            confirmedIdentity = nil
            hasConfirmationError = false
        }
    }

    func beginManualSpecies() {
        guard canEnterManualSpecies, let photo else { return }
        if selectedProposal != nil { retainedProposal = selectedProposal }
        selectedProposal = nil
        isSelectingSpecies = true
        manualDraft = ManualSpeciesDraft(id: UUID(), photoID: photo.id, name: confirmedIdentity?.manualName ?? "")
        hasManualConfirmationError = false
    }

    private func validManualSession(_ sessionID: UUID) -> Bool {
        !closed && !isBusy && !presentsCamera && manualDraft?.id == sessionID &&
        photo != nil && manualDraft?.photoID == photo?.id
    }

    func updateManualName(_ name: String, sessionID: UUID) {
        guard validManualSession(sessionID) else { return }
        manualDraft?.name = name
        hasManualConfirmationError = false
    }

    func confirmManualSpecies(sessionID: UUID) {
        guard validManualSession(sessionID), let draft = manualDraft else { return }
        do {
            let identity = try manualConfirmation.execute(photoID: draft.photoID, name: draft.name)
            confirmedIdentity = identity
            hasConfirmationError = false
            hasManualConfirmationError = false
            manualDraft = nil
            isSelectingSpecies = false
        } catch { hasManualConfirmationError = true }
    }

    func cancelManualSpecies(sessionID: UUID) {
        guard validManualSession(sessionID) else { return }
        manualDraft = nil
        selectedProposal = retainedProposal
        isSelectingSpecies = false
        hasManualConfirmationError = false
    }

    func returnToAIProposals() {
        guard canReturnToAIProposals else { return }
        confirmedIdentity = nil
        selectedProposal = retainedProposal
        hasConfirmationError = false
        hasManualConfirmationError = false
    }

    func cancelSpeciesSelection() {
        guard !closed, !isBusy, !presentsCamera, isSelectingSpecies, confirmedIdentity != nil else { return }
        if let draft = manualDraft { cancelManualSpecies(sessionID: draft.id) }
        else {
            selectedProposal = retainedProposal
            isSelectingSpecies = false
            hasConfirmationError = false
        }
    }

    private func clearIdentification() {
        identificationResult = nil
        resultID = nil
        resultPhotoID = nil
        selectedProposal = nil
        retainedProposal = nil
        isSelectingSpecies = false
        confirmedIdentity = nil
        hasConfirmationError = false
        manualDraft = nil
        hasManualConfirmationError = false
    }

    func identifyPhoto() {
        guard canIdentify, let photo else { return }
        clearIdentification()
        identificationError = nil
        #if DEBUG && targetEnvironment(simulator)
        invocationCount = testInvocationCount?() ?? 0
        #endif
        guard identificationAvailable, configurationIsCurrent() else {
            authorizationState = .unavailable
            return
        }
        pendingPhotoID = photo.id
        continueAuthorization(confirmed: false)
    }

    func confirmAuthorization() {
        guard authorizationState == .awaitingConfirmation, !closed, photo?.id == pendingPhotoID else { return }
        continueAuthorization(confirmed: true)
    }

    func cancelAuthorization() {
        authorizationGeneration += 1
        authorizationTask?.cancel()
        authorizationTask = nil
        pendingPhotoID = nil
        authorizationState = .idle
        identificationError = nil
    }

    private func continueAuthorization(confirmed: Bool) {
        guard let snapshot = photo, snapshot.id == pendingPhotoID else { return }
        guard configurationIsCurrent() else {
            cancelAuthorization()
            authorizationState = .unavailable
            return
        }
        authorizationGeneration += 1
        let request = authorizationGeneration
        authorizationState = confirmed ? .continuing : .checkingAuthorization
        authorizationTask = Task { [weak self, identify, authorize] in
            do {
                let result = try await authorize.execute(confirmed: confirmed) { [weak self] in
                    guard let self, !self.closed, self.authorizationGeneration == request,
                          self.photo?.id == snapshot.id else { throw CancellationError() }
                    guard self.configurationIsCurrent() else { throw SpeciesIdentificationError.configuration }
                    try Task.checkCancellation()
                    self.authorizationState = .continuing
                    return try await identify(snapshot)
                }
                guard let self, !self.closed, self.authorizationGeneration == request, !Task.isCancelled else { return }
                self.authorizationTask = nil
                switch result {
                case .requiresConfirmation: self.authorizationState = .awaitingConfirmation
                case .completed(let continuation):
                    self.pendingPhotoID = nil
                    guard self.configurationIsCurrent() else { self.authorizationState = .unavailable; return }
                    switch continuation {
                    case .unavailable: self.authorizationState = .unavailable
                    case .completed(let value):
                        guard self.photo?.id == snapshot.id else { return }
                        self.identificationResult = try value.validated()
                        self.resultID = UUID()
                        self.resultPhotoID = snapshot.id
                        self.selectedProposal = nil
                        self.confirmedIdentity = nil
                        self.authorizationState = .idle
                    }
                }
                #if DEBUG && targetEnvironment(simulator)
                self.invocationCount = self.testInvocationCount?() ?? 0
                #endif
            } catch {
                guard let self, !self.closed, self.authorizationGeneration == request, !Task.isCancelled else { return }
                self.authorizationTask = nil
                self.pendingPhotoID = nil
                self.authorizationState = .failed
                self.identificationError = error as? SpeciesIdentificationError
                #if DEBUG && targetEnvironment(simulator)
                self.invocationCount = self.testInvocationCount?() ?? 0
                #endif
            }
        }
    }

    /// Transfer closure belongs to Presentation; neither PhotosPickerItem nor UIImage crosses Domain.
    func select(load: @escaping @Sendable () async throws -> Data?) {
        guard !closed, !isBusy, !isEditingManualSpecies else { return }
        generation += 1
        let request = generation
        isLoading = true
        error = nil
        cameraIssue = nil
        task = Task { [weak self, prepare] in
            do {
                guard let data = try await load() else { throw IdentificationPhotoError.transferFailed }
                let prepared = try await prepare.execute(data)
                guard let self, !self.closed, self.generation == request, !Task.isCancelled else { return }
                self.photo = prepared
                self.authorizationState = .idle
                self.clearIdentification()
                self.identificationError = nil
                self.isLoading = false
                self.task = nil
            } catch {
                guard let self, !self.closed, self.generation == request, !Task.isCancelled else { return }
                self.isLoading = false
                self.error = (error as? IdentificationPhotoError) ?? .transferFailed
                self.task = nil
            }
        }
    }

    func takePhoto() {
        guard !closed, !isBusy, !presentsCamera, !isEditingManualSpecies else { return }
        generation += 1
        let request = generation
        isCheckingCamera = true
        error = nil
        cameraIssue = nil
        task = Task { [weak self, camera] in
            let result = try? await camera.execute()
            guard let self, !self.closed, self.generation == request, !Task.isCancelled else { return }
            self.isCheckingCamera = false
            self.task = nil
            guard let result else { return }
            if result == .authorized { self.presentsCamera = true }
            else { self.cameraIssue = result }
        }
    }

    func close() {
        cancelAuthorization()
        closed = true
        generation += 1
        task?.cancel()
        task = nil
        photo = nil
        clearIdentification()
        identificationError = nil
        error = nil
        cameraIssue = nil
        isLoading = false
        isCheckingCamera = false
        presentsCamera = false
    }
}
