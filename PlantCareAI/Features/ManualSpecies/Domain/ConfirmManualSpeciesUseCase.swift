import Foundation

enum ConfirmManualSpeciesError: Error, Equatable { case emptyName }

protocol ConfirmManualSpeciesUseCase {
    func execute(photoID: UUID, name: String) throws -> ConfirmedDraftIdentity
}

/// Local human input, not an inferred common/scientific name or botanical verification.
struct ConfirmManualSpecies: ConfirmManualSpeciesUseCase {
    func execute(photoID: UUID, name: String) throws -> ConfirmedDraftIdentity {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ConfirmManualSpeciesError.emptyName }
        return ConfirmedDraftIdentity(photoID: photoID, source: .manual(name: trimmed))
    }
}
