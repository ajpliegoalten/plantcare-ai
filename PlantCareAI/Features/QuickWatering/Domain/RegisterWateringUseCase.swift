import Foundation

struct RegisterWatering {
    let repository: any CareEventRepository

    func execute(event: CareEvent, now: Date) async throws -> CareEvent {
        let event = Self.normalized(event)
        try Self.validateStructure(event)
        // Data reconciles a committed UUID before checking the current clock.
        guard now.timeIntervalSinceReferenceDate.isFinite else { throw CareEventError.validation }
        return try await repository.saveCareEvent(event)
    }

    static func normalized(_ event: CareEvent) -> CareEvent {
        let note = event.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return CareEvent(id: event.id, plantID: event.plantID, kind: event.kind, occurredAt: event.occurredAt,
                         note: note?.isEmpty == true ? nil : note, createdAt: event.createdAt,
                         timeZoneIdentifier: event.timeZoneIdentifier)
    }

    static func calendar(in zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }

    static func zone(_ identifier: String) throws -> TimeZone {
        guard identifier.contains("/"), !identifier.hasPrefix("Etc/GMT"),
              TimeZone.knownTimeZoneIdentifiers.contains(identifier), let zone = TimeZone(identifier: identifier) else {
            throw CareEventError.validation
        }
        return zone
    }

    static func startOfDay(year: Int, month: Int, day: Int, zone: TimeZone) throws -> Date {
        let calendar = calendar(in: zone)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            throw CareEventError.validation
        }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year, resolved.month == month, resolved.day == day else { throw CareEventError.validation }
        return calendar.startOfDay(for: date)
    }

    static func validateStructure(_ event: CareEvent) throws {
        guard event.occurredAt.timeIntervalSinceReferenceDate.isFinite,
              event.createdAt.timeIntervalSinceReferenceDate.isFinite,
              normalized(event) == event else { throw CareEventError.validation }
        let calendar = calendar(in: try zone(event.timeZoneIdentifier))
        guard calendar.startOfDay(for: event.occurredAt) == event.occurredAt else { throw CareEventError.validation }
    }

    static func validateInsertion(_ event: CareEvent, now: Date) throws {
        try validateStructure(event)
        let calendar = calendar(in: try zone(event.timeZoneIdentifier))
        guard now.timeIntervalSinceReferenceDate.isFinite, event.occurredAt <= now,
              event.occurredAt <= calendar.startOfDay(for: now) else { throw CareEventError.validation }
    }
}
