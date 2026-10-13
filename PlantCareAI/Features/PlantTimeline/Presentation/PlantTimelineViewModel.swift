import Foundation
import UIKit

@MainActor
final class PlantTimelineViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, loaded, failed, notFound }
    let plantID: UUID
    let photos: PlantTimelinePhotoViewModel
    @Published private(set) var state: State = .idle
    @Published private(set) var groups: [PlantTimelineDateFormatter.Group] = []
    enum DeletionState: Equatable { case idle, confirming, deleting, failed }
    @Published private(set) var deletionState: DeletionState = .idle
    // Native alert dismisses its binding before invoking the chosen action.
    // Keep that flag separate from the confirmed snapshot/state until the action resolves.
    @Published var showingDeletionConfirmation = false
    @Published private(set) var deletionTarget: PlantTimelineEntry?
    @Published private(set) var deletionNeedsReconciliation = false
    @Published private(set) var deletionReadFailed = false
    private(set) var deletionPhotoWasReadable = false
    private let deleteCare: (any DeleteCareEventUseCase)?
    private let deletePhoto: (any DeletePlantPhotoUseCase)?
    private let onDeleted: @MainActor (PlantTimelineEntry) -> Void
    private var deletionTask: Task<Void, Never>?
    private var deferredRefresh = false
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
         deleteCare: (any DeleteCareEventUseCase)? = nil, deletePhoto: (any DeletePlantPhotoUseCase)? = nil,
         onDeleted: @escaping @MainActor (PlantTimelineEntry) -> Void = { _ in },
         clock: @escaping () -> Date = Date.init, zone: @escaping () -> TimeZone = { .current },
         sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { try await Task.sleep(for: .seconds($0)) }) {
        self.plantID = plantID; self.load = load; self.photos = photos
        self.deleteCare = deleteCare; self.deletePhoto = deletePhoto; self.onDeleted = onDeleted
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
        guard deletionState != .deleting else { deferredRefresh = true; return }
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
        if deletionState != .deleting { abandonDeletion() }
    }

    func requestDeletion(_ entry: PlantTimelineEntry) {
        guard state == .loaded, deletionState == .idle, entry.plantID == plantID,
              entries.contains(entry) else { return }
        switch entry {
        case .initial: return
        case .care: guard deleteCare != nil else { return }
        case .additional: guard deletePhoto != nil else { return }
        }
        deletionTarget = entry; deletionNeedsReconciliation = false; deletionReadFailed = false
        deletionPhotoWasReadable = photos.image(for: entry.id) != nil
        deletionState = .confirming
        showingDeletionConfirmation = true
    }

    func abandonDeletion() {
        guard deletionState != .deleting else { return }
        showingDeletionConfirmation = false
        deletionTarget = nil; deletionState = .idle; deletionNeedsReconciliation = false
        deletionReadFailed = false; deletionPhotoWasReadable = false
    }

    func confirmDeletion() {
        guard deletionState == .confirming || deletionState == .failed,
              !deletionNeedsReconciliation, let target = deletionTarget else { return }
        if request != nil || state != .loaded { deferredRefresh = true }
        generation += 1; request?.cancel(); request = nil
        showingDeletionConfirmation = false
        deletionState = .deleting
        // Retain this owner until dispatched IO resolves: disappearing cannot cancel a commit.
        deletionTask = Task { [self] in
            do {
                let removed: PlantTimelineEntry
                switch target {
                case .care(let event):
                    guard let deleteCare else { return }
                    removed = .care(try await deleteCare.execute(event))
                case .additional(let photo):
                    guard let deletePhoto else { return }
                    removed = .additional(try await deletePhoto.execute(.additional(photo.id), expected: photo))
                case .initial: return
                }
                entries.removeAll { $0.id == removed.id }
                if removed.isPhoto { photos.remove(removed.id) }
                onDeleted(removed)
                deletionState = .idle; deletionTarget = nil; deletionTask = nil
                updateContext()
            } catch {
                deletionReadFailed = (error as? CareEventError) == .readFailure || (error as? PlantPhotoError) == .readFailure
                deletionNeedsReconciliation = (error as? CareEventError) == .notFound ||
                    (error as? CareEventError) == .conflict || (error as? CareEventError) == .plantNotFound ||
                    (error as? PlantPhotoError) == .notFound || (error as? PlantPhotoError) == .conflict ||
                    (error as? PlantPhotoError) == .plantNotFound || deletionReadFailed
                deletionState = .failed; deletionTask = nil
                if deletionNeedsReconciliation { refresh() }
            }
            if deferredRefresh { deferredRefresh = false; refresh() }
        }
    }

    var deletionIsPhoto: Bool { if case .additional = deletionTarget { return true }; return false }
    var deletionContext: String {
        guard let target = deletionTarget else { return "" }
        let kind: String
        switch target {
        case .care(let event):
            switch event.kind {
            case .watering: kind = String(localized: "care.kind.watering")
            case .fertilizing: kind = String(localized: "care.kind.fertilizing")
            case .pruning: kind = String(localized: "care.kind.pruning")
            case .repotting: kind = String(localized: "care.kind.repotting")
            case .other: kind = String(localized: "care.kind.other")
            }
        default: kind = String(localized: "timeline.photograph")
        }
        return kind + " · " + PlantDetailViewModel.formattedDate(target.elementDate, timeZone: zone())
    }
}
