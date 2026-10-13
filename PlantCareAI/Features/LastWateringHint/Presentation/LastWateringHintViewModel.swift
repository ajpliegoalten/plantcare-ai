import Foundation
import UIKit

@MainActor
final class LastWateringHintViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, loaded(Date?), failed }
    let plantID: UUID
    @Published private(set) var state: State = .idle
    @Published private(set) var now: Date
    @Published private(set) var timeZone: TimeZone
    private let load: (any LoadLastWateringUseCase)?
    private let clock: () -> Date
    private let zone: () -> TimeZone
    private let sleep: @Sendable (TimeInterval) async throws -> Void
    private var request: Task<Void, Never>?
    private var boundary: Task<Void, Never>?
    private var generation = 0
    private var visible = false
    private var deleted = false

    func invalidateDeletedPlant() {
        deleted = true; disappear(); generation += 1
        request?.cancel(); request = nil; state = .idle
    }
    private var observers: [NSObjectProtocol] = []

    init(plantID: UUID, load: (any LoadLastWateringUseCase)?, clock: @escaping () -> Date = Date.init,
         zone: @escaping () -> TimeZone = { .current },
         sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { seconds in
             try await Task.sleep(for: .seconds(seconds))
         }) {
        self.plantID = plantID; self.load = load; self.clock = clock; self.zone = zone; self.sleep = sleep
        now = clock(); timeZone = zone()
    }

    deinit {
        request?.cancel(); boundary?.cancel()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func appear() {
        guard !deleted else { return }
        visible = true
        observeContext()
        updateContext()
        loadIfNeeded()
    }

    func disappear() {
        visible = false
        boundary?.cancel(); boundary = nil
        observers.forEach(NotificationCenter.default.removeObserver); observers = []
        if case .loading = state {
            generation += 1; request?.cancel(); request = nil; state = .idle
        }
    }

    func foreground() {
        guard visible else { return }
        updateContext()
        loadIfNeeded()
    }

    func invalidate() {
        guard !deleted else { return }
        generation += 1
        request?.cancel(); request = nil
        state = .idle
        if visible { loadIfNeeded() }
    }

    // Day/zone/clock changes only reformat; a failed read is not retried here.
    func updateContext() {
        guard !deleted else { return }
        now = clock(); timeZone = zone()
        scheduleBoundary()
    }

    private func loadIfNeeded() {
        guard let load, request == nil else { return }
        switch state { case .idle, .failed: break; case .loading, .loaded: return }
        generation += 1
        let token = generation
        state = .loading
        request = Task { [weak self, plantID] in
            do {
                let date = try await load.execute(for: plantID)
                try Task.checkCancellation()
                guard let self, token == self.generation else { return }
                self.request = nil; self.state = .loaded(date)
            } catch {
                guard let self, token == self.generation else { return }
                self.request = nil
                self.state = error is CancellationError || Task.isCancelled ? .idle : .failed
            }
        }
    }

    private func observeContext() {
        guard observers.isEmpty else { return }
        for name in [Notification.Name.NSSystemTimeZoneDidChange, .NSCalendarDayChanged,
                     UIApplication.significantTimeChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.updateContext() }
            })
        }
    }

    private func scheduleBoundary() {
        boundary?.cancel(); boundary = nil
        guard visible, let next = LastWateringDateFormatter.nextDay(after: now, timeZone: timeZone) else { return }
        let delay = max(0.01, next.timeIntervalSince(now))
        let sleep = sleep
        boundary = Task { [weak self] in
            do { try await sleep(delay); try Task.checkCancellation() } catch { return }
            self?.updateContext()
        }
    }

    func value(compact: Bool) -> String? {
        guard case .loaded(let date) = state else { return nil }
        guard let date else { return String(localized: "lastWatering.none", defaultValue: "Sin riegos registrados") }
        let formatted = LastWateringDateFormatter.string(date, now: now, timeZone: timeZone, compact: compact)
        return compact ? String(localized: "lastWatering.card \(formatted)") : formatted
    }
}
