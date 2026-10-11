import Foundation

enum SpeciesProposalSelection: Equatable, Sendable {
    case primary
    case alternative(index: Int)
}

enum ConfirmSpeciesError: Error, Equatable {
    case invalidResult
    case invalidSelection
}

protocol ConfirmSpeciesUseCase {
    func execute(photoID: UUID, resultID: UUID, result: IdentificationResult,
                 selection: SpeciesProposalSelection) throws -> ConfirmedDraftIdentity
}

struct ConfirmSpecies: ConfirmSpeciesUseCase {
    func execute(photoID: UUID, resultID: UUID, result: IdentificationResult,
                 selection: SpeciesProposalSelection) throws -> ConfirmedDraftIdentity {
        guard (try? result.validated()) != nil, result.outcome == .proposals,
              let primary = result.primary else { throw ConfirmSpeciesError.invalidResult }
        let candidate: SpeciesCandidate
        switch selection {
        case .primary: candidate = primary
        case .alternative(let index):
            guard result.alternatives.indices.contains(index) else { throw ConfirmSpeciesError.invalidSelection }
            candidate = result.alternatives[index]
        }
        return ConfirmedDraftIdentity(photoID: photoID, source: .aiProposal(resultID: resultID,
                                      selection: selection, commonName: candidate.commonName,
                                      scientificName: candidate.scientificName))
    }
}
