import Foundation

enum KeepPlantPhotoAnalysisError: Error, Equatable {
    case validation, notFound, conflict, readFailure, storage
}

struct SavedPlantPhotoAnalysis: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let plantID: UUID
    let identity: PlantPhotoIdentity
    let photoDate: Date
    let queriedAt: Date
    let revision: Int
    let acceptedAt: Date
    let content: PlantPhotoAnalysisContent

    // Swift String equality is Unicode-canonical; acceptance reconciliation must be literal.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.plantID == rhs.plantID && lhs.identity == rhs.identity &&
        lhs.photoDate == rhs.photoDate && lhs.queriedAt == rhs.queriedAt && lhs.revision == rhs.revision &&
        lhs.acceptedAt == rhs.acceptedAt && lhs.content.outcome == rhs.content.outcome &&
        [lhs.content.observations, lhs.content.possibleCauses, lhs.content.checks].enumerated().allSatisfy { index, values in
            let other = [rhs.content.observations, rhs.content.possibleCauses, rhs.content.checks][index]
            return values.count == other.count && zip(values, other).allSatisfy { Array($0.utf8) == Array($1.utf8) }
        }
    }
}

struct PlantPhotoAnalysisAcceptance: Equatable, Sendable {
    let record: SavedPlantPhotoAnalysis
    let source: PlantPhotoDescriptor
}
