import Foundation
import UIKit
import ImageIO

@MainActor
final class PlantPhotoAnalysisViewModel: ObservableObject, Identifiable {
    enum State: Equatable { case preparing, awaitingConsent, analyzing, result, insufficientEvidence, failed }
    let id = UUID()
    let plantID: UUID
    let identity: PlantPhotoIdentity
    let queriedAt: Date
    let timeZone: TimeZone
    let destination: ExternalAIDestinationNotice?
    @Published private(set) var state: State = .preparing
    @Published private(set) var plant: Plant?
    @Published private(set) var photoDate: Date?
    @Published private(set) var image: UIImage?
    @Published private(set) var result: PlantPhotoAnalysis?
    @Published private(set) var errorKey = "analysis.error.read"
    @Published var showingConsent = false
    private let analyze: (any AnalyzePlantPhotoUseCase)?
    private let authorize: AuthorizeExternalAIOperation
    private let configurationIsCurrent: () -> Bool
    private var prepared: PreparedPlantPhotoAnalysis?
    private var task: Task<Void, Never>?
    private var generation = 0
    private var started = false
    private(set) var closed = false
    #if DEBUG && targetEnvironment(simulator)
    var invocationCount: (() -> Int)?
    #endif

    init(plantID: UUID, identity: PlantPhotoIdentity, analyze: (any AnalyzePlantPhotoUseCase)?,
         authorize: AuthorizeExternalAIOperation, destination: ExternalAIDestinationNotice?,
         queriedAt: Date = Date(), timeZone: TimeZone = .current, configurationIsCurrent: @escaping () -> Bool) {
        self.plantID = plantID; self.identity = identity; self.analyze = analyze; self.authorize = authorize
        self.destination = destination; self.queriedAt = queriedAt; self.timeZone = timeZone
        self.configurationIsCurrent = configurationIsCurrent
    }
    deinit { task?.cancel() }

    func start() { guard !started, !closed else { return }; started = true; prepare() }
    func retry() { guard state == .failed, !closed else { return }; prepare() }

    private func prepare() {
        guard task == nil, !closed else { return }
        generation += 1; let token = generation
        state = .preparing; prepared = nil; result = nil
        task = Task { [weak self] in
            guard let self else { return }
            do {
                guard let analyze = self.analyze, self.configurationIsCurrent() else { throw PlantPhotoAnalysisError.configuration }
                let value = try await analyze.prepare(plantID: self.plantID, identity: self.identity, queriedAt: self.queriedAt, timeZone: self.timeZone)
                try Task.checkCancellation()
                let image = try await Self.thumbnail(value.jpeg)
                guard self.isCurrent(token) else { return }
                self.prepared = value; self.plant = value.plant; self.photoDate = value.photo.date; self.image = image
                self.task = nil
                self.send(confirmed: false)
            } catch { self.fail(error, token: token) }
        }
    }

    func acceptConsent() {
        guard state == .awaitingConsent, task == nil, !closed else { return }
        showingConsent = false; send(confirmed: true)
    }
    func cancelConsent() {
        guard state == .awaitingConsent, !closed else { return }
        showingConsent = false; prepared = nil; state = .failed; errorKey = "analysis.error.consentCancelled"
    }

    private func send(confirmed: Bool) {
        guard task == nil, let prepared, let analyze, !closed else { return }
        let token = generation
        state = .analyzing
        task = Task { [weak self] in
            guard let self else { return }
            do {
                guard self.configurationIsCurrent() else { throw PlantPhotoAnalysisError.configuration }
                let authorized = try await self.authorize.execute(confirmed: confirmed) {
                    guard self.configurationIsCurrent(), self.isCurrent(token) else { throw PlantPhotoAnalysisError.configuration }
                    return try await analyze.execute(prepared)
                }
                try Task.checkCancellation()
                guard self.isCurrent(token), self.configurationIsCurrent() else { throw PlantPhotoAnalysisError.configuration }
                self.task = nil
                switch authorized {
                case .requiresConfirmation: self.state = .awaitingConsent; self.showingConsent = true
                case .completed(let result):
                    guard result.plantID == self.plantID, result.identity == self.identity else { throw PlantPhotoAnalysisError.invalidResponse }
                    self.result = result; self.prepared = nil
                    self.state = result.content.outcome == .analysis ? .result : .insufficientEvidence
                }
            } catch { self.fail(error, token: token) }
        }
    }

    private func isCurrent(_ token: Int) -> Bool { !closed && token == generation && !Task.isCancelled }
    private func fail(_ error: Error, token: Int) {
        guard !closed, token == generation else { return }
        task = nil; prepared = nil; result = nil; state = .failed
        switch error as? PlantPhotoAnalysisError {
        case .configuration: errorKey = "analysis.error.configuration"
        case .alreadyAnalyzed: errorKey = "analysis.error.definitive"
        case .notFound: errorKey = "analysis.error.notFound"
        case .photoCorrupt: errorKey = "analysis.error.photo"
        case .contextTooLarge: errorKey = "analysis.error.context"
        case .timeout: errorKey = "analysis.error.timeout"
        case .unauthorized: errorKey = "analysis.error.unauthorized"
        case .rateLimited: errorKey = "analysis.error.rateLimited"
        case .network: errorKey = "analysis.error.network"
        case .rejected, .service: errorKey = "analysis.error.rejected"
        case .invalidResponse: errorKey = "analysis.error.response"
        default:
            if (error as? PlantStorageError) == .photoMissing || (error as? PlantPhotoError) == .photoMissing ||
                (error as? PlantStorageError) == .photoCorrupt || (error as? PlantPhotoError) == .photoCorrupt { errorKey = "analysis.error.photo" }
            else { errorKey = "analysis.error.read" }
        }
    }

    func close() {
        guard !closed else { return }
        closed = true; generation += 1; task?.cancel(); task = nil
        prepared = nil; result = nil; image = nil; plant = nil; photoDate = nil; showingConsent = false
    }

    nonisolated private static func thumbnail(_ data: Data) async throws -> UIImage {
        let task = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1600, kCGImageSourceShouldCacheImmediately: true
                  ] as CFDictionary) else { throw PlantPhotoAnalysisError.photoCorrupt }
            return UIImage(cgImage: cg)
        }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }
}

// Only owns a weak reference to the active modal, never a provisional result cache.
@MainActor
final class PlantPhotoAnalysisPresentationGate {
    private weak var active: PlantPhotoAnalysisViewModel?
    func open(_ make: () -> PlantPhotoAnalysisViewModel) -> PlantPhotoAnalysisViewModel? {
        guard active == nil || active?.closed == true else { return nil }
        let value = make(); active = value; return value
    }
}
