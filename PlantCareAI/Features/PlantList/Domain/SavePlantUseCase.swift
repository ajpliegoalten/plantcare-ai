import Foundation

struct SavePlant: Sendable {
    let repository: any PlantRepository

    func execute(_ plant: Plant, initialPhoto: Data) async throws {
        try Self.validate(plant)
        guard !initialPhoto.isEmpty else { throw PlantStorageError.validation }
        try await repository.savePlant(plant, initialPhoto: initialPhoto)
    }

    static func validate(_ plant: Plant) throws {
        let fields = [plant.name, plant.confirmedSpecies] + plant.careSheet.requiredFields
        guard fields.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              plant.createdAt.timeIntervalSince1970.isFinite else {
            throw PlantStorageError.validation
        }
    }
}
