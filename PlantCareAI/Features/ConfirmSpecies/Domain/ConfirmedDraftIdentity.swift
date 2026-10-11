import Foundation

/// Human choice in an ephemeral draft, not botanical verification or a saved plant.
struct ConfirmedDraftIdentity: Equatable, Sendable {
    let photoID: UUID
    enum Source: Equatable, Sendable {
        case aiProposal(resultID: UUID, selection: SpeciesProposalSelection, commonName: String?, scientificName: String?)
        case manual(name: String)
    }
    let source: Source

    var resultID: UUID? {
        if case .aiProposal(let id, _, _, _) = source { return id }
        return nil
    }
    var proposal: SpeciesProposalSelection? {
        if case .aiProposal(_, let selection, _, _) = source { return selection }
        return nil
    }
    var commonName: String? {
        if case .aiProposal(_, _, let name, _) = source { return name }
        return nil
    }
    var scientificName: String? {
        if case .aiProposal(_, _, _, let name) = source { return name }
        return nil
    }
    var manualName: String? {
        if case .manual(let name) = source { return name }
        return nil
    }
}
