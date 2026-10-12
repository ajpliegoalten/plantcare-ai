import Foundation
import UIKit

@MainActor
final class QuickWateringViewModel: ObservableObject, Identifiable {
    enum State: Equatable { case editing, saving, error(CareEventError), saved }
    let id = UUID()
    let plant: Plant
    let photo: UIImage?
    @Published private(set) var occurredAt: Date
    @Published private(set) var note = ""
    @Published private(set) var state: State = .editing
    @Published private(set) var displayZone: TimeZone
    private var originZone: String
    private var snapshot: CareEvent?
    private var invalidDateSelection = false
    private let register: RegisterWatering
    private let now: () -> Date
    private let zone: () -> TimeZone
    private let onSaved: @MainActor (CareEvent) -> Void

    init(plant: Plant, photo: UIImage? = nil, register: RegisterWatering,
         now: @escaping () -> Date = { Date() }, zone: @escaping () -> TimeZone = { .current },
         onSaved: @escaping @MainActor (CareEvent) -> Void) {
        self.plant = plant; self.photo = photo; self.register = register
        self.now = now; self.zone = zone; self.onSaved = onSaved
        let current = zone()
        displayZone = current; originZone = current.identifier
        occurredAt = RegisterWatering.calendar(in: current).startOfDay(for: now())
    }

    var isSaving: Bool { state == .saving }
    var calendar: Calendar { RegisterWatering.calendar(in: displayZone) }
    var today: Date { calendar.startOfDay(for: now()) }
    // DatePicker ranges are absolute instants, not civil dates. Keep the selected
    // instant representable when the zone/clock changes; Domain rejects a future insertion.
    var latestSelectableDate: Date { max(now(), occurredAt) }
    var yesterday: Date { calendar.date(byAdding: .day, value: -1, to: today)! }
    var dateDescription: String { PlantDetailViewModel.formattedDate(occurredAt, timeZone: displayZone) }

    func refreshDisplayZone() { displayZone = zone() } // Representation only, never edits the snapshot.

    private func edited() {
        snapshot = nil
        state = .editing
    }

    func setNote(_ value: String) {
        guard !isSaving, state != .saved else { return }
        note = value; edited()
    }

    func selectDate(_ date: Date) {
        guard !isSaving, state != .saved else { return }
        let current = zone()
        guard date.timeIntervalSinceReferenceDate.isFinite else {
            snapshot = nil; invalidDateSelection = true; state = .error(.validation); return
        }
        invalidDateSelection = false
        displayZone = current
        occurredAt = RegisterWatering.calendar(in: current).startOfDay(for: date)
        originZone = current.identifier
        edited()
    }

    func selectDay(offset: Int) {
        refreshDisplayZone()
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return }
        selectDate(date)
    }

    func save() async {
        guard !isSaving, state != .saved else { return }
        guard !invalidDateSelection else { state = .error(.validation); return }
        let event = snapshot ?? RegisterWatering.normalized(CareEvent(id: UUID(), plantID: plant.id, kind: .watering,
            occurredAt: occurredAt, note: note, createdAt: now(), timeZoneIdentifier: originZone))
        snapshot = event
        state = .saving // Lock before suspension; do not discard committed success on late cancellation.
        do {
            let confirmed = try await register.execute(event: event, now: now())
            guard confirmed == event else { throw CareEventError.conflict }
            onSaved(confirmed)
            state = .saved
        } catch { state = .error((error as? CareEventError) ?? .storage) }
    }
}
