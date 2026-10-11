import Foundation

struct ConfirmedPlantSnapshot: Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    let photo: IdentificationPhoto
    let identity: ConfirmedDraftIdentity
    let careSheet: CareSheet

    func plant() throws -> Plant {
        guard id != photo.id, identity.photoID == photo.id,
              createdAt.timeIntervalSince1970.isFinite else { throw PlantStorageError.validation }
        try GenerateCareSheet.validate(identity)
        let sheet = try GenerateCareSheet.validate(careSheet)
        let name: String
        let species: String
        switch identity.source {
        case .manual(let text):
            name = text.trimmingCharacters(in: .whitespacesAndNewlines)
            species = name
        case .aiProposal(_, _, let common, let scientific):
            name = common ?? scientific ?? ""
            if let common, let scientific, common != scientific { species = "\(common) (\(scientific))" }
            else { species = name }
        }
        return Plant(id: id, name: name, confirmedSpecies: species, createdAt: createdAt,
                     location: nil, careSheet: sheet)
    }
}

protocol SaveConfirmedPlantUseCase: Sendable {
    func execute(_ snapshot: ConfirmedPlantSnapshot,
                 willCommit: @escaping @Sendable () async throws -> Void) async throws -> Plant
}

struct SaveConfirmedPlant: SaveConfirmedPlantUseCase {
    let repository: any PlantRepository
    let photoValidator: any PreparedPlantPhotoValidating

    func execute(_ snapshot: ConfirmedPlantSnapshot,
                 willCommit: @escaping @Sendable () async throws -> Void) async throws -> Plant {
        let plant = try snapshot.plant()
        try Task.checkCancellation()
        try await photoValidator.validate(snapshot.photo)
        try Task.checkCancellation()
        // Last cancellable boundary. Once dispatched, acknowledge a successful commit.
        try await willCommit()
        do { try await SavePlant(repository: repository).execute(plant, initialPhoto: snapshot.photo.jpeg) }
        catch PlantStorageError.duplicateID {
            guard try await repository.loadPlants().first(where: { $0.id == plant.id }) == plant,
                  try await repository.loadInitialPhoto(for: plant.id) == snapshot.photo.jpeg else {
                throw PlantStorageError.duplicateID
            }
        }
        return plant
    }
}
