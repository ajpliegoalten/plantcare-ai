import Foundation
import SwiftData

@Model
final class PersistedPlantPhotoAnalysis {
    @Attribute(.unique) var id: UUID
    var plantID: UUID
    var identityKind: String
    var photoID: UUID
    var photoDate: Date
    var queriedAt: Date
    var revision: Int
    var acceptedAt: Date
    var contentData: Data
    var sourceCreatedAt: Date

    init(_ snapshot: PlantPhotoAnalysisAcceptance) throws {
        let record = snapshot.record
        id = record.id; plantID = record.plantID
        switch record.identity {
        case .initial(let id): identityKind = "initial"; photoID = id
        case .additional(let id): identityKind = "additional"; photoID = id
        }
        photoDate = record.photoDate; queriedAt = record.queriedAt; revision = record.revision
        acceptedAt = record.acceptedAt; sourceCreatedAt = snapshot.source.createdAt
        contentData = try JSONEncoder().encode(record.content)
    }

    func snapshot() throws -> PlantPhotoAnalysisAcceptance {
        let identity: PlantPhotoIdentity
        switch identityKind {
        case "initial": identity = .initial(photoID)
        case "additional": identity = .additional(photoID)
        default: throw KeepPlantPhotoAnalysisError.readFailure
        }
        let content = try JSONDecoder().decode(PlantPhotoAnalysisContent.self, from: contentData)
        let record = SavedPlantPhotoAnalysis(id: id, plantID: plantID, identity: identity, photoDate: photoDate,
            queriedAt: queriedAt, revision: revision, acceptedAt: acceptedAt, content: content)
        let snapshot = PlantPhotoAnalysisAcceptance(record: record,
            source: .init(id: identity, date: photoDate, createdAt: sourceCreatedAt))
        try KeepPlantPhotoAnalysis.validate(snapshot)
        return snapshot
    }
}
