import Foundation
import UIKit
import ImageIO

@MainActor
final class PlantCardViewModel: ObservableObject, Identifiable {
    enum PhotoState { case idle, loading, loaded(UIImage), failed }
    @Published private(set) var plant: Plant
    nonisolated let id: UUID
    @Published private(set) var photoState: PhotoState = .idle
    private let loadPhoto: LoadInitialPlantPhoto
    let lastWatering: LastWateringHintViewModel
    private var generation = 0
    private var deleted = false

    func invalidateDeletedPlant() {
        deleted = true; generation += 1; photoState = .idle
        lastWatering.invalidateDeletedPlant()
    }

    init(plant: Plant, loadPhoto: LoadInitialPlantPhoto, loadLastWatering: (any LoadLastWateringUseCase)? = nil) {
        self.plant = plant
        self.id = plant.id
        self.loadPhoto = loadPhoto
        self.lastWatering = LastWateringHintViewModel(plantID: plant.id, load: loadLastWatering)
    }

    func applyUpdatedPlant(_ plant: Plant) {
        guard !deleted, plant.id == id else { return }
        self.plant = plant
    }

    func load() async {
        guard !deleted, case .idle = photoState else { return }
        generation += 1
        let request = generation
        photoState = .loading
        do {
            let data = try await loadPhoto.execute(for: id)
            try Task.checkCancellation()
            // Presentation-only thumbnail. Original bytes are not retained or rewritten.
            let image = try await Task.detached(priority: .userInitiated) {
                try Self.prepareImage(data)
            }.value
            try Task.checkCancellation()
            guard request == generation else { return }
            photoState = .loaded(image)
        } catch {
            guard request == generation else { return }
            photoState = (error is CancellationError || Task.isCancelled) ? .idle : .failed
        }
    }

    func retry() async {
        guard case .failed = photoState else { return }
        photoState = .idle
        await load()
    }

    func cancelLoading() {
        guard case .loading = photoState else { return }
        generation += 1
        photoState = .idle
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
