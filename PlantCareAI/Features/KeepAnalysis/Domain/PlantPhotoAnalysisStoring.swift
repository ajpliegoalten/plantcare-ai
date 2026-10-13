import Foundation

protocol SavedPlantPhotoAnalysisReading: Sendable {
    func loadSavedAnalyses(for plantID: UUID) async throws -> [SavedPlantPhotoAnalysis]
}

protocol PlantPhotoAnalysisStoring: SavedPlantPhotoAnalysisReading {
    func saveAccepted(_ snapshot: PlantPhotoAnalysisAcceptance) async throws -> SavedPlantPhotoAnalysis
}
