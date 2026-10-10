import Foundation

struct UpdatePlant: Sendable {
    let repository: any PlantRepository

    static func normalized(name: String, location: String?) throws -> (name: String, location: String?) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw PlantStorageError.validation }
        let location = location?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (name, location?.isEmpty == false ? location : nil)
    }

    func execute(id: UUID, name: String, location: String?) async throws -> Plant {
        let fields = try Self.normalized(name: name, location: location)
        return try await repository.updatePlant(id: id, name: fields.name, location: fields.location)
    }
}
