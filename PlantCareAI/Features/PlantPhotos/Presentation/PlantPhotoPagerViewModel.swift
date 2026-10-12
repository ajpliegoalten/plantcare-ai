import Foundation
import UIKit

@MainActor
final class PlantPhotoPagerViewModel: ObservableObject {
    enum MetadataState { case idle, loading, loaded, failed }
    enum ImageState { case idle, loading, loaded(UIImage), failed }
    @Published private(set) var metadataState: MetadataState = .idle
    @Published private(set) var imageState: ImageState = .idle
    @Published private(set) var descriptors: [PlantPhotoDescriptor]
    @Published private(set) var selected: PlantPhotoIdentity
    @Published private(set) var displayZone: TimeZone = .current
    private let plant: Plant
    private let loadMetadata: LoadPlantPhotos
    private let loadAdditional: LoadPlantPhoto
    private let loadInitial: LoadInitialPlantPhoto
    private var photos: [PlantPhoto] = []
    private var cache: [PlantPhotoIdentity: UIImage] = [:]
    private var lru: [PlantPhotoIdentity] = []
    private var metadataGeneration = 0
    private var imageGeneration = 0
    private var metadataTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?
    private var active = false

    init(plant: Plant, loadMetadata: LoadPlantPhotos, loadAdditional: LoadPlantPhoto, loadInitial: LoadInitialPlantPhoto) {
        self.plant = plant; self.loadMetadata = loadMetadata; self.loadAdditional = loadAdditional
        self.loadInitial = loadInitial
        selected = .initial(plant.id)
        descriptors = PlantPhotoDescriptor.ordered(plant: plant, photos: [])
    }

    var current: PlantPhotoDescriptor { descriptors.first { $0.id == selected }! }
    var index: Int { descriptors.firstIndex { $0.id == selected }! }
    var isComplete: Bool { if case .loaded = metadataState { return true }; return false }
    var canPrevious: Bool { isComplete && index > 0 }
    var canNext: Bool { isComplete && index + 1 < descriptors.count }
    var cachedImageCount: Int { cache.count }
    var initialImage: UIImage? { cache[.initial(plant.id)] }

    func appear() {
        refreshDisplayZone()
        active = true
        if !isComplete { refresh() }
        loadSelected()
    }
    func refreshDisplayZone() { displayZone = .current }

    func refresh() {
        metadataGeneration += 1; let request = metadataGeneration
        metadataTask?.cancel(); metadataState = .loading
        metadataTask = Task { [weak self, loadMetadata, plant] in
            do {
                let result = try await loadMetadata.execute(for: plant.id)
                try Task.checkCancellation()
                guard let self, self.active, request == self.metadataGeneration else { return }
                self.photos = result
                self.descriptors = PlantPhotoDescriptor.ordered(plant: plant, photos: result)
                if !self.descriptors.contains(where: { $0.id == self.selected }) { self.selected = .initial(plant.id); self.loadSelected() }
                self.metadataState = .loaded
            } catch {
                guard let self, self.active, request == self.metadataGeneration else { return }
                self.metadataState = .failed
            }
        }
    }

    func select(_ identity: PlantPhotoIdentity) {
        guard active, isComplete, descriptors.contains(where: { $0.id == identity }), selected != identity else { return }
        selected = identity; loadSelected()
    }
    func previous() { if canPrevious { select(descriptors[index - 1].id) } }
    func next() { if canNext { select(descriptors[index + 1].id) } }

    func committed(_ photo: PlantPhoto, image: UIImage) {
        guard active, photo.plantID == plant.id else { return }
        metadataGeneration += 1; metadataTask?.cancel()
        photos.removeAll { $0.id == photo.id }; photos.append(photo)
        descriptors = PlantPhotoDescriptor.ordered(plant: plant, photos: photos)
        selected = .additional(photo.id)
        imageGeneration += 1; imageTask?.cancel()
        insert(image, for: selected); imageState = .loaded(image)
        refresh() // Failed reconciliation is metadata error, not a failed commit.
    }

    func retryImage() { loadSelected(force: true) }

    private func insert(_ image: UIImage, for identity: PlantPhotoIdentity) {
        cache[identity] = image; lru.removeAll { $0 == identity }; lru.append(identity)
        while cache.count > 3 {
            let position = lru.firstIndex { $0 != .initial(plant.id) && $0 != selected }!
            let victim = lru.remove(at: position); cache.removeValue(forKey: victim)
        }
    }

    private func loadSelected(force: Bool = false) {
        guard active else { return }
        imageGeneration += 1; let request = imageGeneration; let identity = selected
        imageTask?.cancel()
        if !force, let image = cache[identity] { insert(image, for: identity); imageState = .loaded(image); return }
        imageState = .loading
        imageTask = Task { [weak self, loadInitial, loadAdditional, plant] in
            do {
                let data: Data
                switch identity {
                case .initial: data = try await loadInitial.execute(for: plant.id)
                case .additional(let id): data = try await loadAdditional.execute(id: id, for: plant.id)
                }
                try Task.checkCancellation()
                let decode = Task.detached { try AddPlantPhotoViewModel.thumbnail(data) }
                let image = try await withTaskCancellationHandler(operation: { try await decode.value }, onCancel: { decode.cancel() })
                try Task.checkCancellation()
                guard let self, self.active, request == self.imageGeneration, self.selected == identity else { return }
                self.insert(image, for: identity); self.imageState = .loaded(image)
            } catch {
                guard let self, self.active, request == self.imageGeneration, self.selected == identity else { return }
                self.imageState = .failed
            }
        }
    }

    func disappear() {
        active = false; metadataGeneration += 1; imageGeneration += 1
        metadataTask?.cancel(); imageTask?.cancel(); metadataTask = nil; imageTask = nil
        selected = .initial(plant.id); imageState = .idle
        cache.removeAll(); lru.removeAll()
        if !isComplete { metadataState = .idle }
    }
}
