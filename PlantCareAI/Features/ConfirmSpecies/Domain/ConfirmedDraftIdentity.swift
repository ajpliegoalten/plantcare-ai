import Foundation

/// Human choice in an ephemeral draft, not botanical verification or a saved plant.
struct ConfirmedDraftIdentity: Equatable, Sendable {
    let photoID: UUID
    let resultID: UUID
    let commonName: String?
    let scientificName: String?
    let proposal: SpeciesProposalSelection
}
