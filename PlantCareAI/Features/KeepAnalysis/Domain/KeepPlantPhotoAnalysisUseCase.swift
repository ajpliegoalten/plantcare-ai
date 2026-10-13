import Foundation

protocol KeepPlantPhotoAnalysisUseCase: Sendable {
    func execute(_ snapshot: PlantPhotoAnalysisAcceptance) async throws -> SavedPlantPhotoAnalysis
}

struct KeepPlantPhotoAnalysis: KeepPlantPhotoAnalysisUseCase {
    let repository: any PlantPhotoAnalysisStoring

    static func validate(_ snapshot: PlantPhotoAnalysisAcceptance) throws {
        let value = snapshot.record
        guard value.identity == snapshot.source.id, value.photoDate == snapshot.source.date,
              [value.photoDate, value.queriedAt, value.acceptedAt, snapshot.source.createdAt].allSatisfy({ $0.timeIntervalSince1970.isFinite }),
              value.revision > 0, value.content.outcome == .analysis else { throw KeepPlantPhotoAnalysisError.validation }
        if case .initial(let id) = value.identity, id != value.plantID { throw KeepPlantPhotoAnalysisError.validation }
        do { _ = try value.content.validated() } catch { throw KeepPlantPhotoAnalysisError.validation }
    }

    func execute(_ snapshot: PlantPhotoAnalysisAcceptance) async throws -> SavedPlantPhotoAnalysis {
        try Self.validate(snapshot)
        return try await repository.saveAccepted(snapshot)
    }
}
