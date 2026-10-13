import Foundation

enum PlantPhotoAnalysisError: Error, Equatable {
    case configuration, notFound, alreadyAnalyzed, busy, contextTooLarge, photoCorrupt, readFailure
    case network, timeout, unauthorized, rateLimited, rejected, service, invalidResponse
}

struct PlantPhotoAnalysisContent: Codable, Equatable, Sendable {
    enum Outcome: String, Codable, Sendable { case analysis, insufficientEvidence }
    let outcome: Outcome
    let observations: [String]
    let possibleCauses: [String]
    let checks: [String]

    func validated() throws -> Self {
        for array in [observations, possibleCauses, checks] {
            guard array.count <= 5, array.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 1000 }) else {
                throw PlantPhotoAnalysisError.invalidResponse
            }
        }
        guard !observations.isEmpty,
              outcome == .analysis ? !checks.isEmpty : (possibleCauses.isEmpty && checks.isEmpty) else {
            throw PlantPhotoAnalysisError.invalidResponse
        }
        return self
    }
}

// Provisional only. No persistence, acceptance timestamp, or result cache.
struct PlantPhotoAnalysis: Equatable, Sendable {
    let plantID: UUID
    let identity: PlantPhotoIdentity
    let queriedAt: Date
    let revision: Int
    let content: PlantPhotoAnalysisContent
}

// Future keep-analysis reader must return only definitive texts with their source photo date.
struct AcceptedPlantPhotoAnalysis: Sendable {
    let plantID: UUID
    let identity: PlantPhotoIdentity
    let photoDate: Date
    let content: PlantPhotoAnalysisContent
}

protocol AcceptedPlantPhotoAnalysisReading: Sendable {
    func loadAccepted(for plantID: UUID) async throws -> [AcceptedPlantPhotoAnalysis]
}
