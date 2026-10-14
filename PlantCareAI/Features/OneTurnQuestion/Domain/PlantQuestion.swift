import Foundation

enum PlantQuestionError: Error, Equatable {
    case configuration, notFound, stale, busy, invalidQuestion, contextTooLarge, readFailure
    case network, timeout, unauthorized, rateLimited, rejected, service, invalidResponse
}
struct PlantQuestionAnswer: Codable, Equatable, Sendable {
    let answer: String
    func validated() throws -> Self {
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, answer.count <= 6000 else { throw PlantQuestionError.invalidResponse }
        return self
    }
}
struct PlantQuestionResult: Equatable, Sendable {
    let requestID: UUID
    let plantID: UUID
    let question: String
    let answer: PlantQuestionAnswer
}
