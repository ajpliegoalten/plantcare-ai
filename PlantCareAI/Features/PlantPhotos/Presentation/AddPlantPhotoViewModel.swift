import Foundation
import UIKit
import ImageIO

@MainActor
final class AddPlantPhotoViewModel: ObservableObject, Identifiable {
    enum State: Equatable { case editing, validating, saving, error(PlantPhotoError), saved }
    let id = UUID()
    let plant: Plant
    @Published private(set) var state: State = .editing
    @Published private(set) var photo: IdentificationPhoto?
    @Published private(set) var preview: UIImage?
    @Published private(set) var occurredAt: Date
    @Published private(set) var displayZone: TimeZone
    @Published private(set) var isLoading = false
    @Published private(set) var isCheckingCamera = false
    @Published private(set) var preparationError: IdentificationPhotoError?
    @Published private(set) var cameraIssue: CameraAccessResult?
    @Published var presentsCamera = false
    private var closed = false
    private var generation = 0
    private var task: Task<Void, Never>?
    private var snapshot: PlantPhoto?
    private var originZone: String
    private var validDate = true
    private let prepare: PrepareIdentificationPhoto
    private let validate: any PreparedPlantPhotoValidating
    private let camera: CheckCameraAccess
    private let add: AddPlantPhoto
    private let now: () -> Date
    private let zone: () -> TimeZone
    private let onSaved: @MainActor (PlantPhoto, UIImage) -> Void
    #if DEBUG && targetEnvironment(simulator)
    var testSelections: [String: Data] = [:]
    #endif

    init(plant: Plant, prepare: PrepareIdentificationPhoto, validate: any PreparedPlantPhotoValidating,
         camera: CheckCameraAccess, add: AddPlantPhoto, now: @escaping () -> Date = { Date() },
         zone: @escaping () -> TimeZone = { .current }, onSaved: @escaping @MainActor (PlantPhoto, UIImage) -> Void) {
        self.plant = plant; self.prepare = prepare; self.validate = validate; self.camera = camera
        self.add = add; self.now = now; self.zone = zone; self.onSaved = onSaved
        let current = zone(); displayZone = current; originZone = current.identifier
        occurredAt = AddPlantPhoto.calendar(in: current).startOfDay(for: now())
    }

    var isSaving: Bool { state == .saving }
    var isBusy: Bool { isLoading || isCheckingCamera || presentsCamera || state == .validating || isSaving }
    var canClose: Bool { !isSaving }
    var canSave: Bool { !closed && !isBusy && state != .saved && photo != nil && preview != nil && validDate }
    var calendar: Calendar { AddPlantPhoto.calendar(in: displayZone) }
    var latestSelectableDate: Date { max(now(), occurredAt) }
    func refreshDisplayZone() { displayZone = zone() }

    func selectDate(_ date: Date) {
        guard !closed, !isBusy, state != .saved else { return }
        guard date.timeIntervalSinceReferenceDate.isFinite else {
            validDate = false; snapshot = nil; state = .error(.validation); return
        }
        let current = zone(); displayZone = current; originZone = current.identifier
        occurredAt = AddPlantPhoto.calendar(in: current).startOfDay(for: date)
        validDate = occurredAt <= calendar.startOfDay(for: now())
        snapshot = nil; state = validDate ? .editing : .error(.validation)
    }

    func select(_ transfer: @escaping @Sendable () async throws -> Data?) {
        guard !closed, !isSaving, state != .saved, state != .validating else { return }
        generation += 1; let request = generation
        task?.cancel(); isLoading = true; preparationError = nil
        task = Task { [weak self, prepare] in
            do {
                guard let data = try await transfer() else {
                    guard let self, !self.closed, request == self.generation else { return }
                    self.isLoading = false; return
                }
                let prepared = try await prepare.execute(data)
                let decode = Task.detached { try Self.thumbnail(prepared.jpeg) }
                let image = try await withTaskCancellationHandler(operation: { try await decode.value }, onCancel: { decode.cancel() })
                try Task.checkCancellation()
                guard let self, !self.closed, request == self.generation else { return }
                self.photo = prepared; self.preview = image; self.snapshot = nil
                self.state = .editing; self.isLoading = false
            } catch {
                guard let self, !self.closed, request == self.generation else { return }
                self.isLoading = false
                if !(error is CancellationError) { self.preparationError = (error as? IdentificationPhotoError) ?? .transferFailed }
            }
        }
    }

    func requestCamera() {
        guard !closed, !isBusy, state != .saved else { return }
        generation += 1; let request = generation
        isCheckingCamera = true; cameraIssue = nil
        task = Task { [weak self, camera] in
            do {
                let result = try await camera.execute()
                guard let self, !self.closed, request == self.generation else { return }
                self.isCheckingCamera = false
                if result == .authorized { self.presentsCamera = true } else { self.cameraIssue = result }
            } catch {
                guard let self, !self.closed, request == self.generation else { return }
                self.isCheckingCamera = false
            }
        }
    }

    func save() async {
        guard canSave, let photo, let preview else { return }
        let request = generation
        let record = snapshot ?? PlantPhoto(id: UUID(), plantID: plant.id, occurredAt: occurredAt,
            createdAt: now(), timeZoneIdentifier: originZone, width: photo.width, height: photo.height)
        snapshot = record; state = .validating
        do {
            try AddPlantPhoto.validateStructure(record)
            try await validate.validate(photo)
            try Task.checkCancellation()
            guard !closed, request == generation, self.photo?.id == photo.id, snapshot == record else { return }
            state = .saving // Commit dispatched only after the session has been checked; lock before await.
            let confirmed = try await add.execute(photo: record, jpeg: photo.jpeg)
            guard confirmed == record else { throw PlantPhotoError.conflict }
            onSaved(confirmed, preview)
            state = .saved
        } catch {
            guard !closed, request == generation else { return }
            state = .error((error as? PlantPhotoError) ?? .storage)
        }
    }

    func close() {
        guard canClose else { return }
        closed = true; generation += 1; task?.cancel(); task = nil
        photo = nil; preview = nil; snapshot = nil; presentsCamera = false
    }

    nonisolated static func thumbnail(_ data: Data) throws -> UIImage {
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw PlantPhotoError.photoCorrupt }
        try Task.checkCancellation()
        return UIImage(cgImage: image)
    }
}
