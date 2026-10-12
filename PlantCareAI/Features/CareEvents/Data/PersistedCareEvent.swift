import Foundation
import SwiftData

@Model
final class PersistedCareEvent {
    @Attribute(.unique) var id: UUID
    var plantID: UUID
    var kind: String
    var occurredAt: Date
    var note: String?
    var createdAt: Date
    var timeZoneIdentifier: String

    init(_ event: CareEvent) {
        id = event.id; plantID = event.plantID; kind = event.kind.rawValue
        occurredAt = event.occurredAt; note = event.note; createdAt = event.createdAt
        timeZoneIdentifier = event.timeZoneIdentifier
    }

    func domain() throws -> CareEvent {
        guard let kind = CareEvent.Kind(rawValue: kind) else { throw CareEventError.storage }
        let event = CareEvent(id: id, plantID: plantID, kind: kind, occurredAt: occurredAt, note: note,
                              createdAt: createdAt, timeZoneIdentifier: timeZoneIdentifier)
        do { try RegisterCareEvent.validateStructure(event) } catch { throw CareEventError.storage }
        return event
    }
}
