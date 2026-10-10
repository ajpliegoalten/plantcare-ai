import Foundation

@MainActor
final class IdentificationPhotoViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published private(set) var photo: IdentificationPhoto?
    @Published private(set) var isLoading = false
    @Published private(set) var isCheckingCamera = false
    enum AuthorizationState { case idle, checkingAuthorization, awaitingConfirmation, continuing, failed, unavailable }
    @Published private(set) var authorizationState: AuthorizationState = .idle
    var isAuthorizing: Bool { [.checkingAuthorization, .awaitingConfirmation, .continuing].contains(authorizationState) }
    var isBusy: Bool { isLoading || isCheckingCamera || isAuthorizing }
    var canIdentify: Bool { photo != nil && !isBusy && !presentsCamera && !closed }
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

    init(prepare: PrepareIdentificationPhoto, camera: CheckCameraAccess, authorize: AuthorizeExternalAIOperation, identify: @escaping (IdentificationPhoto) async throws -> IdentificationContinuationResult = { _ in .unavailable }) {
        self.prepare = prepare
        self.camera = camera
        self.authorize = authorize
        self.identify = identify
    }

    deinit { task?.cancel(); authorizationTask?.cancel() }

    func identifyPhoto() {
        guard canIdentify, let photo else { return }
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
    }

    private func continueAuthorization(confirmed: Bool) {
        guard let snapshot = photo, snapshot.id == pendingPhotoID else { return }
        authorizationGeneration += 1
        let request = authorizationGeneration
        authorizationState = confirmed ? .continuing : .checkingAuthorization
        authorizationTask = Task { [weak self, identify, authorize] in
            do {
                let result = try await authorize.execute(confirmed: confirmed) { [weak self] in
                    guard let self, !self.closed, self.authorizationGeneration == request,
                          self.photo?.id == snapshot.id else { throw CancellationError() }
                    try Task.checkCancellation()
                    self.authorizationState = .continuing
                    return try await identify(snapshot)
                }
                guard let self, !self.closed, self.authorizationGeneration == request, !Task.isCancelled else { return }
                self.authorizationTask = nil
                switch result {
                case .requiresConfirmation: self.authorizationState = .awaitingConfirmation
                case .completed:
                    self.pendingPhotoID = nil
                    self.authorizationState = .unavailable
                }
                #if DEBUG && targetEnvironment(simulator)
                self.invocationCount = self.testInvocationCount?() ?? 0
                #endif
            } catch {
                guard let self, !self.closed, self.authorizationGeneration == request, !Task.isCancelled else { return }
                self.authorizationTask = nil
                self.pendingPhotoID = nil
                self.authorizationState = .failed
            }
        }
    }

    /// Transfer closure belongs to Presentation; neither PhotosPickerItem nor UIImage crosses Domain.
    func select(load: @escaping @Sendable () async throws -> Data?) {
        guard !closed, !isBusy else { return }
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
        guard !closed, !isBusy else { return }
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
        error = nil
        cameraIssue = nil
        isLoading = false
        isCheckingCamera = false
        presentsCamera = false
    }
}
