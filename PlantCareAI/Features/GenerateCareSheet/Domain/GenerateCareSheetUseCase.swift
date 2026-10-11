import Foundation

struct GenerateCareSheet: Sendable {
    let repository: any CareSheetGenerationRepository

    func execute(identity: ConfirmedDraftIdentity, photoID: UUID) async throws -> CareSheet {
        guard identity.photoID == photoID else { throw CareSheetGenerationError.invalidInput }
        try Self.validate(identity)
        try Task.checkCancellation()
        return try Self.validate(await repository.generate(identity: identity))
    }

    static func validate(_ identity: ConfirmedDraftIdentity) throws {
        let names: [String]
        switch identity.source {
        case .manual(let name): names = [name]
        case .aiProposal(_, _, let common, let scientific): names = [common, scientific].compactMap { $0 }
        }
        guard !names.isEmpty, names.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 2000 }) else {
            throw CareSheetGenerationError.invalidInput
        }
    }

    static func validate(_ sheet: CareSheet) throws -> CareSheet {
        let fields = sheet.requiredFields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard fields.allSatisfy({ !$0.isEmpty && $0.count <= 1000 }) else { throw CareSheetGenerationError.invalidResponse }
        return CareSheet(light: fields[0], watering: fields[1], humidity: fields[2], temperature: fields[3], substrate: fields[4], fertilizer: fields[5])
    }
}
