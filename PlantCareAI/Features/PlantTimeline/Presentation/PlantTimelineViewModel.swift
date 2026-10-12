import Foundation
import UIKit

@MainActor
final class PlantTimelineViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, loaded, failed, notFound }
    let plantID: UUID
    let photos: PlantTimelinePhotoViewModel
    @Published private(set) var state: State = .idle
    @Published private(set) var groups: [PlantTimelineDateFormatter.Group] = []
    private(set) var entries: [PlantTimelineEntry] = []
    private let load: any LoadPlantTimelineUseCase
    private let clock: () -> Date
    private let zone: () -> TimeZone
    private let sleep: @Sendable (TimeInterval) async throws -> Void
    private var active = false
    private var generation = 0
    private var request: Task<Void, Never>?
    private var boundary: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    init(plantID: UUID, load: any LoadPlantTimelineUseCase, photos: PlantTimelinePhotoViewModel,
         clock: @escaping () -> Date = Date.init, zone: @escaping () -> TimeZone = { .current },
         sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { try await Task.sleep(for: .seconds($0)) }) {
        self.plantID = plantID; self.load = load; self.photos = photos
        self.clock = clock; self.zone = zone; self.sleep = sleep
    }

    deinit {
        request?.cancel(); boundary?.cancel()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    var noRecords: Bool { entries.count == 1 && entries.first?.id == .initial(plantID) }
    var noCare: Bool { !entries.contains { if case .care = $0 { return true }; return false } }
    var originIsLast: Bool { groups.last?.entries.last?.id == .initial(plantID) }

    func appear() {
        guard !active else { return }
        active = true; photos.appear(); observeContext(); updateContext(); refresh()
    }
    func foreground() {
        guard active else { return }
        updateContext(); refresh()
    }
    func refresh() {
        guard active, request == nil else { return }
        generation += 1; let token = generation
        state = .loading; entries = []; groups = []
        // A metadata refresh is a new image session, not stale completeness.
        photos.reset(preservingViewport: true)
        request = Task { [weak self, load, plantID] in
            do {
                let result = try await load.execute(for: plantID)
                try Task.checkCancellation()
                guard let self, self.active, token == self.generation else { return }
                self.request = nil
                guard let result else { self.state = .notFound; return }
                self.entries = result.filter { $0.plantID == plantID }
                self.photos.setEntries(self.entries)
                self.updateContext(); self.state = .loaded
            } catch {
                guard let self, self.active, token == self.generation else { return }
                self.request = nil; self.state = .failed
            }
        }
    }

    func updateContext() {
        guard active else { return }
        let now = clock(), timeZone = zone()
        groups = PlantTimelineDateFormatter.groups(entries: entries, now: now, timeZone: timeZone)
        boundary?.cancel(); boundary = nil
        guard let next = LastWateringDateFormatter.nextDay(after: now, timeZone: timeZone) else { return }
        let delay = max(0.01, next.timeIntervalSince(now)), sleep = sleep
        boundary = Task { [weak self] in
            do { try await sleep(delay); try Task.checkCancellation() } catch { return }
            self?.updateContext()
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

    func disappear() {
        active = false; generation += 1; request?.cancel(); request = nil
        boundary?.cancel(); boundary = nil
        observers.forEach(NotificationCenter.default.removeObserver); observers = []
        photos.disappear(); entries = []; groups = []; state = .idle
    }
}
