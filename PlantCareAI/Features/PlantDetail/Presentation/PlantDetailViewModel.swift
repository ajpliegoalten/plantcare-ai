import Foundation
import UIKit
import ImageIO

@MainActor
final class PlantDetailViewModel: ObservableObject {
    enum State { case loading, loaded(Plant), notFound, failed }
    enum PhotoState { case idle, loading, loaded(UIImage), failed }
    let id: UUID
    @Published private(set) var state: State = .loading
    @Published private(set) var photoState: PhotoState = .idle
    private let loadDetail: LoadPlantDetail
    private let loadPhoto: LoadInitialPlantPhoto
    private var metadataGeneration = 0
    private var photoGeneration = 0
    private var metadataPending = false
    private let update: UpdatePlant
    private let onUpdated: @MainActor (Plant) -> Void
    private let registerCare: RegisterCareEvent?
    let lastWatering: LastWateringHintViewModel
    private let onWatering: @MainActor (UUID) -> Void
    @Published private(set) var careConfirmation: CareEvent?
    private var careSession: UUID?
    @Published private(set) var photoPager: PlantPhotoPagerViewModel?
    @Published private(set) var photoConfirmation: PlantPhoto?
    var makeAddPhoto: ((Plant, @escaping @MainActor (PlantPhoto, UIImage) -> Void) -> AddPlantPhotoViewModel)?
    var makePhotoPager: ((Plant) -> PlantPhotoPagerViewModel)?
    private var photoSession: UUID?

    func photoEditor() -> AddPlantPhotoViewModel? {
        guard case .loaded(let plant) = state, let makeAddPhoto else { return nil }
        photoConfirmation = nil
        let session = UUID(); photoSession = session
        return makeAddPhoto(plant) { [weak self] photo, image in
            guard let self, self.photoSession == session, photo.plantID == self.id else { return }
            self.photoSession = nil; self.photoConfirmation = photo
            self.photoPager?.committed(photo, image: image)
        }
    }

    init(id: UUID, loadDetail: LoadPlantDetail, loadPhoto: LoadInitialPlantPhoto, update: UpdatePlant, registerCare: RegisterCareEvent? = nil, loadLastWatering: (any LoadLastWateringUseCase)? = nil, onWatering: @escaping @MainActor (UUID) -> Void = { _ in }, onUpdated: @escaping @MainActor (Plant) -> Void = { _ in }) {
        self.id = id
        self.loadDetail = loadDetail
        self.loadPhoto = loadPhoto
        self.update = update
        self.onUpdated = onUpdated
        self.registerCare = registerCare
        self.lastWatering = LastWateringHintViewModel(plantID: id, load: loadLastWatering)
        self.onWatering = onWatering
    }

    var formPhoto: UIImage? {
        if let photoPager { return photoPager.initialImage }
        if case .loaded(let image) = photoState { return image }; return nil
    }

    func careEditor() -> RegisterCareViewModel? {
        guard case .loaded(let plant) = state, let registerCare else { return nil }
        careConfirmation = nil
        let session = UUID()
        careSession = session
        return RegisterCareViewModel(plant: plant, photo: formPhoto, register: registerCare) { [weak self] event in
            guard let self, self.careSession == session, event.plantID == self.id else { return }
            self.careConfirmation = event
            self.careSession = nil
            if event.kind == .watering {
                self.lastWatering.invalidate()
                self.onWatering(self.id)
            }
        }
    }

    func editor() -> EditPlantViewModel? {
        guard case .loaded(let plant) = state else { return nil }
        return EditPlantViewModel(plant: plant, photo: formPhoto, update: update) { [weak self] plant in
            self?.applyUpdatedPlant(plant)
        }
    }

    func applyUpdatedPlant(_ plant: Plant) {
        guard plant.id == id else { return }
        metadataGeneration += 1
        metadataPending = false
        state = .loaded(plant)
        onUpdated(plant)
    }

    func load() async {
        if case .loaded = state {
            lastWatering.appear()
            if let photoPager { photoPager.appear(); return }
            await loadImage()
            return
        }
        guard case .loading = state, !metadataPending else { return }
        metadataPending = true
        metadataGeneration += 1
        let request = metadataGeneration
        do {
            let plant = try await loadDetail.execute(for: id)
            try Task.checkCancellation()
            guard request == metadataGeneration else { return }
            metadataPending = false
            guard let plant else { state = .notFound; return }
            state = .loaded(plant)
            lastWatering.appear() // Independent of photograph IO/decode.
            if let makePhotoPager {
                photoPager = makePhotoPager(plant); photoPager?.appear(); return
            }
            await loadImage()
        } catch {
            guard request == metadataGeneration else { return }
            metadataPending = false
            state = (error is CancellationError || Task.isCancelled) ? .loading : .failed
        }
    }

    private func loadImage() async {
        guard case .loaded = state, case .idle = photoState else { return }
        photoGeneration += 1
        let request = photoGeneration
        photoState = .loading
        do {
            let data = try await loadPhoto.execute(for: id)
            try Task.checkCancellation()
            let image = try await Task.detached(priority: .userInitiated) {
                try Self.prepareImage(data)
            }.value
            try Task.checkCancellation()
            guard request == photoGeneration else { return }
            photoState = .loaded(image)
        } catch {
            guard request == photoGeneration else { return }
            photoState = (error is CancellationError || Task.isCancelled) ? .idle : .failed
        }
    }

    func retryPhoto() async {
        guard case .failed = photoState else { return }
        photoState = .idle
        await loadImage()
    }

    func cancelLoading() {
        photoPager?.disappear()
        photoConfirmation = nil
        photoSession = nil
        lastWatering.disappear()
        if metadataPending {
            metadataGeneration += 1
            metadataPending = false
            state = .loading
        }
        if case .loading = photoState {
            photoGeneration += 1
            photoState = .idle
        }
    }

    static func formattedDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func visibleLocation(_ location: String?) -> String? {
        guard let location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return location
    }

    nonisolated private static func prepareImage(_ data: Data) throws -> UIImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw PlantStorageError.photoCorrupt }
        return UIImage(cgImage: thumbnail)
    }
}
