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
    private let registerWatering: RegisterWatering?
    @Published private(set) var wateringConfirmation: CareEvent?
    private var wateringSession: UUID?

    init(id: UUID, loadDetail: LoadPlantDetail, loadPhoto: LoadInitialPlantPhoto, update: UpdatePlant, registerWatering: RegisterWatering? = nil, onUpdated: @escaping @MainActor (Plant) -> Void = { _ in }) {
        self.id = id
        self.loadDetail = loadDetail
        self.loadPhoto = loadPhoto
        self.update = update
        self.onUpdated = onUpdated
        self.registerWatering = registerWatering
    }

    private var formPhoto: UIImage? { if case .loaded(let image) = photoState { return image }; return nil }

    func wateringEditor() -> QuickWateringViewModel? {
        guard case .loaded(let plant) = state, let registerWatering else { return nil }
        wateringConfirmation = nil
        let session = UUID()
        wateringSession = session
        return QuickWateringViewModel(plant: plant, photo: formPhoto, register: registerWatering) { [weak self] event in
            guard let self, self.wateringSession == session, event.plantID == self.id else { return }
            self.wateringConfirmation = event
            self.wateringSession = nil
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
