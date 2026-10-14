import Foundation

struct AskPlantQuestion: AskPlantQuestionUseCase {
    let detail: LoadPlantDetail
    let care: any CareEventRepository
    let analyses: any SavedPlantPhotoAnalysisReading
    let repository: any PlantQuestionRepository
    let gate: PlantQuestionOperationGate
    func prepare(plantID: UUID, question: String, queriedAt: Date, timeZone: TimeZone) async throws -> PreparedPlantQuestion {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 2000 else { throw PlantQuestionError.invalidQuestion }
        guard let plant = try await detail.execute(for: plantID), plant.id == plantID else { throw PlantQuestionError.notFound }
        let events = try await care.loadCareEvents(for: plantID)
        let records = try await analyses.loadSavedAnalyses(for: plantID)
        let context = try BuildPlantQuestionContext().execute(plant: plant, question: text, care: events, analyses: records, queriedAt: queriedAt, timeZone: timeZone)
        try Task.checkCancellation()
        return .init(requestID: UUID(), plant: plant, context: context)
    }
    private func validate(_ expected: Plant) async throws {
        guard let current = try await detail.execute(for: expected.id), current.id == expected.id else { throw PlantQuestionError.notFound }
        guard current == expected else { throw PlantQuestionError.stale }
        try Task.checkCancellation()
    }
    func execute(_ prepared: PreparedPlantQuestion) async throws -> PlantQuestionResult {
        let id = prepared.plant.id, requestID = prepared.requestID
        try await gate.begin(plantID: id, requestID: requestID)
        do {
            try await validate(prepared.plant)
            let answer = try await repository.ask(context: prepared.context).validated()
            try Task.checkCancellation(); try await validate(prepared.plant)
            await gate.end(plantID: id, requestID: requestID)
            return .init(requestID: requestID, plantID: id, question: prepared.context.question, answer: answer)
        } catch { await gate.end(plantID: id, requestID: requestID); throw error }
    }
}
