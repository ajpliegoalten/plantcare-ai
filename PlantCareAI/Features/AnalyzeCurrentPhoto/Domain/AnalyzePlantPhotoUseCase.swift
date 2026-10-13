import Foundation

struct AnalyzePlantPhoto: AnalyzePlantPhotoUseCase {
    let detail: LoadPlantDetail
    let care: any CareEventRepository
    let photos: any PlantPhotoRepository
    let initial: LoadInitialPlantPhoto
    let repository: any PlantPhotoAnalysisRepository
    let gate: PlantPhotoAnalysisOperationGate
    // nil means this product does not yet have the keep-analysis capability, not a successful empty disk read.
    var acceptedReader: (any AcceptedPlantPhotoAnalysisReading)? = nil
    let validateJPEG: @Sendable (Data) async throws -> Void

    private func descriptor(plant: Plant, identity: PlantPhotoIdentity) async throws -> PlantPhotoDescriptor {
        switch identity {
        case .initial(let id):
            guard id == plant.id else { throw PlantPhotoAnalysisError.notFound }
            return .init(id: identity, date: plant.createdAt, createdAt: plant.createdAt)
        case .additional(let id):
            guard let photo = try await photos.loadPhotos(for: plant.id).first(where: { $0.id == id && $0.plantID == plant.id }) else {
                throw PlantPhotoAnalysisError.notFound
            }
            return .init(id: identity, date: photo.occurredAt, createdAt: photo.createdAt)
        }
    }

    private func accepted(for plantID: UUID, excluding identity: PlantPhotoIdentity) async throws -> [AcceptedPlantPhotoAnalysis] {
        let records = try await acceptedReader?.loadAccepted(for: plantID) ?? []
        guard !records.contains(where: { $0.plantID == plantID && $0.identity == identity }) else { throw PlantPhotoAnalysisError.alreadyAnalyzed }
        return records
    }

    func prepare(plantID: UUID, identity: PlantPhotoIdentity, queriedAt: Date, timeZone: TimeZone) async throws -> PreparedPlantPhotoAnalysis {
        guard let plant = try await detail.execute(for: plantID), plant.id == plantID else { throw PlantPhotoAnalysisError.notFound }
        let photo = try await descriptor(plant: plant, identity: identity)
        let previous = try await accepted(for: plantID, excluding: identity)
        let events = try await care.loadCareEvents(for: plantID)
        let context = try BuildPlantAnalysisContext().execute(plant: plant, photo: photo, care: events, accepted: previous, queriedAt: queriedAt, timeZone: timeZone)
        try Task.checkCancellation()
        let jpeg: Data
        switch identity {
        case .initial: jpeg = try await initial.execute(for: plantID)
        case .additional(let id): jpeg = try await photos.loadPhoto(id: id, for: plantID)
        }
        guard !jpeg.isEmpty, jpeg.count <= 5 * 1024 * 1024 else { throw PlantPhotoAnalysisError.photoCorrupt }
        try await validateJPEG(jpeg)
        try Task.checkCancellation()
        return .init(plant: plant, photo: photo, jpeg: jpeg, context: context, queriedAt: queriedAt)
    }

    func execute(_ prepared: PreparedPlantPhotoAnalysis) async throws -> PlantPhotoAnalysis {
        let id = prepared.plant.id, identity = prepared.photo.id
        try await gate.begin(plantID: id, identity: identity)
        do {
            try Task.checkCancellation()
            guard let plant = try await detail.execute(for: id), plant == prepared.plant,
                  try await descriptor(plant: plant, identity: identity) == prepared.photo else { throw PlantPhotoAnalysisError.notFound }
            _ = try await accepted(for: id, excluding: identity)
            let content = try await repository.analyze(jpeg: prepared.jpeg, context: prepared.context).validated()
            try Task.checkCancellation()
            // An origin removed while the provider was answering cannot publish a stale result.
            guard let current = try await detail.execute(for: id), current == prepared.plant,
                  try await descriptor(plant: current, identity: identity) == prepared.photo else { throw PlantPhotoAnalysisError.notFound }
            let result = PlantPhotoAnalysis(plantID: id, identity: identity, queriedAt: prepared.queriedAt, revision: 1, content: content)
            await gate.end(plantID: id, identity: identity)
            return result
        } catch {
            await gate.end(plantID: id, identity: identity)
            throw error
        }
    }
}
