#if DEBUG && targetEnvironment(simulator)
import Foundation

final class PlantQuestionTestFixture: PlantQuestionRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private let mode: String
    init(mode: String) { self.mode = mode }
    var invocations: Int { lock.withLock { count } }
    func ask(context: PlantQuestionContext) async throws -> PlantQuestionAnswer {
        let number = lock.withLock { count += 1; return count }
        if mode == "slow" { try await Task.sleep(for: .seconds(30)) }
        if mode == "retry" && number == 1 { throw PlantQuestionError.network }
        let suffix = mode == "long" ? String(repeating: "Orientación prudente, comprueba el sustrato y las condiciones reales. ", count: 60) : "Comprueba las condiciones reales antes de actuar."
        return .init(answer: "Respuesta \(number): \(context.question). Ubicación: \(context.currentUserLocation ?? "sin ubicación"). \(suffix)")
    }
}
#endif
