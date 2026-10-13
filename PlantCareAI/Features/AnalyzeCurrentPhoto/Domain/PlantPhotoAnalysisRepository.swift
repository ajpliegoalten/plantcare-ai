import Foundation

protocol PlantPhotoAnalysisRepository: Sendable {
    func analyze(jpeg: Data, context: PlantAnalysisContext) async throws -> PlantPhotoAnalysisContent
}

struct PreparedPlantPhotoAnalysis: Sendable {
    let plant: Plant
    let photo: PlantPhotoDescriptor
    let jpeg: Data
    let context: PlantAnalysisContext
    let queriedAt: Date
}

protocol AnalyzePlantPhotoUseCase: Sendable {
    func prepare(plantID: UUID, identity: PlantPhotoIdentity, queriedAt: Date, timeZone: TimeZone) async throws -> PreparedPlantPhotoAnalysis
    func execute(_ prepared: PreparedPlantPhotoAnalysis) async throws -> PlantPhotoAnalysis
}

actor PlantPhotoAnalysisOperationGate {
    private struct Key: Hashable { let plantID: UUID; let identity: PlantPhotoIdentity }
    private var active: Set<Key> = []
    func begin(plantID: UUID, identity: PlantPhotoIdentity) throws {
        guard active.insert(Key(plantID: plantID, identity: identity)).inserted else { throw PlantPhotoAnalysisError.busy }
    }
    func end(plantID: UUID, identity: PlantPhotoIdentity) { active.remove(Key(plantID: plantID, identity: identity)) }
}
