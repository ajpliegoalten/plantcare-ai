import Foundation

protocol PlantQuestionRepository: Sendable { func ask(context: PlantQuestionContext) async throws -> PlantQuestionAnswer }
struct PreparedPlantQuestion: Sendable {
    let requestID: UUID
    let plant: Plant
    let context: PlantQuestionContext
}
protocol AskPlantQuestionUseCase: Sendable {
    func prepare(plantID: UUID, question: String, queriedAt: Date, timeZone: TimeZone) async throws -> PreparedPlantQuestion
    func execute(_ prepared: PreparedPlantQuestion) async throws -> PlantQuestionResult
}
actor PlantQuestionOperationGate {
    private var active: [UUID: UUID] = [:]
    func begin(plantID: UUID, requestID: UUID) throws {
        guard active[plantID] == nil else { throw PlantQuestionError.busy }
        active[plantID] = requestID
    }
    func end(plantID: UUID, requestID: UUID) { if active[plantID] == requestID { active[plantID] = nil } }
}
