import Foundation

protocol LoadPlantTimelineUseCase: Sendable {
    func execute(for plantID: UUID) async throws -> [PlantTimelineEntry]?
    func snapshot(for plantID: UUID) async throws -> PlantTimelineSnapshot?
}

struct PlantTimelineSnapshot: Sendable {
    let entries: [PlantTimelineEntry]
    let analyses: [PlantPhotoIdentity: SavedPlantPhotoAnalysis]
}

extension LoadPlantTimelineUseCase {
    func snapshot(for plantID: UUID) async throws -> PlantTimelineSnapshot? {
        try await execute(for: plantID).map { .init(entries: $0, analyses: [:]) }
    }
}

struct LoadPlantTimeline: LoadPlantTimelineUseCase {
    let detail: LoadPlantDetail
    let care: any CareEventRepository
    let photos: any PlantPhotoRepository
    var analyses: (any SavedPlantPhotoAnalysisReading)? = nil

    func snapshot(for plantID: UUID) async throws -> PlantTimelineSnapshot? {
        guard let entries = try await execute(for: plantID) else { return nil }
        let saved = try await analyses?.loadSavedAnalyses(for: plantID) ?? []
        var associated: [PlantPhotoIdentity: SavedPlantPhotoAnalysis] = [:]
        for record in saved {
            let key: PlantTimelineIdentity
            switch record.identity {
            case .initial(let id): key = .initial(id)
            case .additional(let id): key = .additional(id)
            }
            guard record.plantID == plantID, let entry = entries.first(where: { $0.id == key }),
                  entry.elementDate == record.photoDate, associated[record.identity] == nil else {
                throw KeepPlantPhotoAnalysisError.readFailure
            }
            associated[record.identity] = record
        }
        return .init(entries: entries, analyses: associated)
    }

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
