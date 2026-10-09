import Foundation

struct Plant: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    // Only a human-confirmed species belongs in a saved Plant, never an AI candidate.
    let confirmedSpecies: String
    let createdAt: Date
    let location: String?
    let careSheet: CareSheet
    var initialPhotoID: UUID { id }
}
