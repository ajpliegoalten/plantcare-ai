import Foundation
import UIKit

@MainActor
final class PlantTimelinePhotoViewModel: ObservableObject {
    // Images live only in the bounded cache, never in a second published state.
    enum State: Equatable { case idle, loading, loaded, failed }
    @Published private(set) var states: [PlantTimelineIdentity: State] = [:]
    private let plantID: UUID
    private let read: @Sendable (PlantTimelineIdentity, UUID) async throws -> Data
    private let decode: @Sendable (Data) async throws -> UIImage
    private var allowed: Set<PlantTimelineIdentity> = []
    private var visible: Set<PlantTimelineIdentity> = []
    private var owners: [PlantTimelineIdentity: Set<UUID>] = [:]
    private let defaultOwner = UUID()
    private var hiding: [PlantTimelineIdentity: Task<Void, Never>] = [:]
    private var queue: [PlantTimelineIdentity] = []
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var running: [PlantTimelineIdentity: UUID] = [:]
    private var tokens: [PlantTimelineIdentity: UUID] = [:]
    private var cache: [PlantTimelineIdentity: UIImage] = [:]
    private var lru: [PlantTimelineIdentity] = []
    private var active = false
    private var generation = 0

    init(plantID: UUID, loadInitial: LoadInitialPlantPhoto, loadAdditional: LoadPlantPhoto) {
        self.plantID = plantID
        read = { identity, plantID in
            switch identity {
            case .initial: return try await loadInitial.execute(for: plantID)
            case .additional(let id): return try await loadAdditional.execute(id: id, for: plantID)
            case .care: throw PlantStorageError.validation
            }
        }
        decode = { try await PlantTimelinePhotoViewModel.thumbnail($0) }
    }

    // Injectable read/decode boundaries exercise cancellation and concurrency without JPEG fixtures.
    init(plantID: UUID, read: @escaping @Sendable (PlantTimelineIdentity, UUID) async throws -> Data,
         decode: @escaping @Sendable (Data) async throws -> UIImage = { try await PlantTimelinePhotoViewModel.thumbnail($0) }) {
        self.plantID = plantID; self.read = read; self.decode = decode
    }

    nonisolated static func thumbnail(_ data: Data) async throws -> UIImage {
        let task = Task.detached { try AddPlantPhotoViewModel.thumbnail(data) }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }

    var cachedCount: Int { cache.count }
    var inFlightCount: Int { tasks.count }
    func image(for identity: PlantTimelineIdentity) -> UIImage? { cache[identity] }
    func state(for identity: PlantTimelineIdentity) -> State { states[identity] ?? .idle }
    func appear() { active = true }
    func setEntries(_ entries: [PlantTimelineEntry]) {
        allowed = Set(entries.filter { $0.plantID == plantID && $0.isPhoto }.map(\.id))
    }

    func show(_ identity: PlantTimelineIdentity, owner: UUID? = nil) {
        guard active, allowed.contains(identity) else { return }
        owners[identity, default: []].insert(owner ?? defaultOwner)
        hiding.removeValue(forKey: identity)?.cancel()
        visible.insert(identity)
        if cache[identity] != nil { touch(identity); return }
        if running[identity] != nil, tokens[identity] != nil { states[identity] = .loading; return }
        guard state(for: identity) == .idle else { return }
        enqueue(identity)
    }
    func hide(_ identity: PlantTimelineIdentity, owner: UUID? = nil) {
        guard active else { return }
        owners[identity]?.remove(owner ?? defaultOwner)
        guard owners[identity]?.isEmpty != false else { return }
        owners[identity] = nil
        visible.remove(identity); queue.removeAll { $0 == identity }
        if state(for: identity) == .loading { states[identity] = .idle }
        hiding.removeValue(forKey: identity)?.cancel()
        let session = generation
        // Reparenting a stable identity to a different day can remove and insert its
        // row in one UI turn. Let the new owner retain an existing read/decode rather
        // than cancelling/re-reading solely because the group's identity changed.
        hiding[identity] = Task { [weak self] in
            await Task.yield()
            guard !Task.isCancelled, let self, session == self.generation,
                  !self.visible.contains(identity) else { return }
            self.hiding[identity] = nil
            // Keep draining cancelled IO counted until completion.
            if let token = self.running[identity] { self.tokens[identity] = nil; self.tasks[token]?.cancel() }
        }
    }
    func retry(_ identity: PlantTimelineIdentity) {
        guard active, visible.contains(identity), allowed.contains(identity), state(for: identity) == .failed else { return }
        enqueue(identity)
    }
    private func enqueue(_ identity: PlantTimelineIdentity) {
        guard running[identity] == nil, !queue.contains(identity) else { return }
        states[identity] = .loading; queue.append(identity); pump()
    }
    private func pump() {
        guard active else { return }
        while tasks.count < 2, !queue.isEmpty {
            let identity = queue.removeFirst()
            guard visible.contains(identity), allowed.contains(identity) else { states[identity] = .idle; continue }
            let token = UUID(), session = generation
            tokens[identity] = token
            running[identity] = token
            tasks[token] = Task { [weak self, read, decode, plantID] in
                do {
                    let data = try await read(identity, plantID)
                    try Task.checkCancellation()
                    let image = try await decode(data)
                    try Task.checkCancellation()
                    self?.complete(identity, token: token, session: session, image: image)
                } catch { self?.complete(identity, token: token, session: session, image: nil) }
            }
        }
    }
    private func complete(_ identity: PlantTimelineIdentity, token: UUID, session: Int, image: UIImage?) {
        tasks[token] = nil
        guard session == generation else { pump(); return }
        if running[identity] == token { running[identity] = nil }
        if active, tokens[identity] == token, visible.contains(identity), allowed.contains(identity) {
            tokens[identity] = nil
            if let image {
                cache[identity] = image; touch(identity); states[identity] = .loaded
                while cache.count > 3 {
                    let victim = lru.removeFirst(); cache[victim] = nil; states[victim] = .idle
                    // No reload on eviction; only a subsequent row appearance requests it.
                }
            } else { states[identity] = .failed }
        } else if active, visible.contains(identity), allowed.contains(identity), state(for: identity) == .idle {
            enqueue(identity) // Row was revisited while its cancelled request drained.
        }
        pump()
    }
    private func touch(_ identity: PlantTimelineIdentity) {
        lru.removeAll { $0 == identity }; lru.append(identity)
    }
    func reset() {
        generation += 1; tasks.values.forEach { $0.cancel() }; running = [:]; tokens = [:]
        hiding.values.forEach { $0.cancel() }; hiding = [:]; owners = [:]
        queue = []; visible = []; allowed = []; cache = [:]; lru = []; states = [:]
    }
    func disappear() { active = false; reset() }

    deinit { tasks.values.forEach { $0.cancel() }; hiding.values.forEach { $0.cancel() } }
}
