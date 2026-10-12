import Foundation

protocol LoadPlantTimelineUseCase: Sendable {
    func execute(for plantID: UUID) async throws -> [PlantTimelineEntry]?
}

struct LoadPlantTimeline: LoadPlantTimelineUseCase {
    let detail: LoadPlantDetail
    let care: any CareEventRepository
    let photos: any PlantPhotoRepository

    func execute(for plantID: UUID) async throws -> [PlantTimelineEntry]? {
        guard let plant = try await detail.execute(for: plantID), plant.id == plantID else { return nil }
        try Task.checkCancellation()
        let events = try await care.loadCareEvents(for: plantID)
        try Task.checkCancellation()
        let additional = try await photos.loadPhotos(for: plantID)
        try Task.checkCancellation()
        // All reads must succeed before publishing. Input/fetch order is not visual order.
        return [.initial(plant)] + events.filter { $0.plantID == plantID }.map(PlantTimelineEntry.care)
            + additional.filter { $0.plantID == plantID }.map(PlantTimelineEntry.additional)
    }
}
