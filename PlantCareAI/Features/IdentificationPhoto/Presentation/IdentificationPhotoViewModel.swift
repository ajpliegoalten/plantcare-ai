import Foundation

@MainActor
final class IdentificationPhotoViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published private(set) var photo: IdentificationPhoto?
    @Published private(set) var isLoading = false
    @Published private(set) var isCheckingCamera = false
    var isBusy: Bool { isLoading || isCheckingCamera }
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
    #endif

    init(prepare: PrepareIdentificationPhoto, camera: CheckCameraAccess) {
        self.prepare = prepare
        self.camera = camera
    }

    deinit { task?.cancel() }

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
