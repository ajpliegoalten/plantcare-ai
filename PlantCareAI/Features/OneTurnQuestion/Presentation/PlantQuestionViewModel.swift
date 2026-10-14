import Foundation
import UIKit

@MainActor
final class PlantQuestionViewModel: ObservableObject, Identifiable {
    enum State: Equatable { case idle, preparing, awaitingConsent, asking, answered, failed }
    let id = UUID()
    let plantID: UUID
    @Published private(set) var plant: Plant?
    @Published private(set) var image: UIImage?
    @Published var question = ""
    @Published private(set) var state: State = .idle
    @Published private(set) var result: PlantQuestionResult?
    @Published private(set) var errorKey = "question.error.read"
    @Published var showingConsent = false
    let destination: ExternalAIDestinationNotice?
    private let ask: (any AskPlantQuestionUseCase)?
    private let authorize: AuthorizeExternalAIOperation
    private let configurationIsCurrent: () -> Bool
    private let now: () -> Date
    private let zone: () -> TimeZone
    private var prepared: PreparedPlantQuestion?
    private var task: Task<Void, Never>?
    private var generation = 0
    @Published private(set) var closed = false
    #if DEBUG && targetEnvironment(simulator)
    var invocationCount: (() -> Int)?
    #endif
    init(plant: Plant, image: UIImage?, ask: (any AskPlantQuestionUseCase)?, authorize: AuthorizeExternalAIOperation,
         destination: ExternalAIDestinationNotice?, now: @escaping () -> Date = { Date() }, zone: @escaping () -> TimeZone = { .current },
         configurationIsCurrent: @escaping () -> Bool) {
        self.plantID = plant.id; self.plant = plant; self.image = image; self.ask = ask
        self.authorize = authorize; self.destination = destination; self.now = now; self.zone = zone
        self.configurationIsCurrent = configurationIsCurrent
    }
    deinit { task?.cancel() }
    var busy: Bool { state == .preparing || state == .awaitingConsent || state == .asking }
    var canSend: Bool {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return !closed && !busy && !text.isEmpty && text.count <= 2000
    }
    func send() {
        guard canSend, task == nil else { return }
        generation += 1; let token = generation, text = question, date = now(), timeZone = zone()
        result = nil; prepared = nil; state = .preparing
        task = Task { [weak self] in
            guard let self else { return }
            do {
                guard let ask = self.ask, self.configurationIsCurrent() else { throw PlantQuestionError.configuration }
                let value = try await ask.prepare(plantID: self.plantID, question: text, queriedAt: date, timeZone: timeZone)
                try Task.checkCancellation()
                guard self.current(token), value.plant.id == self.plantID else { return }
                self.prepared = value; self.task = nil; self.dispatch(confirmed: false)
            } catch { self.fail(error, token: token) }
        }
    }
    func acceptConsent() {
        guard state == .awaitingConsent, !closed, task == nil else { return }
        showingConsent = false; dispatch(confirmed: true)
    }
    func cancelConsent() {
        guard state == .awaitingConsent, !closed else { return }
        cancelRequest(); state = .failed; errorKey = "question.error.consentCancelled"
    }
    private func dispatch(confirmed: Bool) {
        guard let prepared, let ask, task == nil, !closed else { return }
        let token = generation; state = .asking
        task = Task { [weak self] in
            guard let self else { return }
            do {
                guard self.configurationIsCurrent() else { throw PlantQuestionError.configuration }
                let value = try await self.authorize.execute(confirmed: confirmed) {
                    guard self.current(token), self.configurationIsCurrent() else { throw PlantQuestionError.configuration }
                    return try await ask.execute(prepared)
                }
                try Task.checkCancellation()
                guard self.current(token) else { return }
                guard self.configurationIsCurrent() else { throw PlantQuestionError.configuration }
                self.task = nil
                switch value {
                case .requiresConfirmation: self.state = .awaitingConsent; self.showingConsent = true
                case .completed(let result):
                    guard result.plantID == self.plantID, result.requestID == prepared.requestID, result.question == prepared.context.question else { throw PlantQuestionError.invalidResponse }
                    self.result = result; self.prepared = nil; self.state = .answered
                }
            } catch { self.fail(error, token: token) }
        }
    }
    private func current(_ token: Int) -> Bool { !closed && token == generation && !Task.isCancelled }
    private func fail(_ error: Error, token: Int) {
        guard !closed, token == generation else { return }
        task = nil; prepared = nil; result = nil; showingConsent = false; state = .failed
        switch error as? PlantQuestionError {
        case .configuration: errorKey = "question.error.configuration"
        case .notFound: errorKey = "question.error.notFound"
        case .stale: errorKey = "question.error.stale"
        case .busy: errorKey = "question.error.busy"
        case .invalidQuestion: errorKey = "question.error.question"
        case .contextTooLarge: errorKey = "question.error.context"
        case .network: errorKey = "question.error.network"
        case .timeout: errorKey = "question.error.timeout"
        case .unauthorized: errorKey = "question.error.unauthorized"
        case .rateLimited: errorKey = "question.error.rateLimited"
        case .rejected, .service: errorKey = "question.error.rejected"
        case .invalidResponse: errorKey = "question.error.response"
        default: errorKey = "question.error.read"
        }
    }
    func cancelRequest() {
        guard !closed else { return }
        generation += 1; task?.cancel(); task = nil; prepared = nil; result = nil; showingConsent = false; state = .idle
    }
    func close() {
        guard !closed else { return }
        cancelRequest(); closed = true; question = ""; plant = nil; image = nil
    }
}
