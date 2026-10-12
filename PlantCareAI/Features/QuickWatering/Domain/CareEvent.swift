import Foundation

struct CareEvent: Equatable, Sendable, Identifiable {
    enum Kind: String, Sendable { case watering }
    let id: UUID
    let plantID: UUID
    let kind: Kind
    let occurredAt: Date
    let note: String?
    let createdAt: Date
    let timeZoneIdentifier: String

    static func == (lhs: CareEvent, rhs: CareEvent) -> Bool {
        lhs.id == rhs.id && lhs.plantID == rhs.plantID && lhs.kind == rhs.kind &&
        lhs.occurredAt == rhs.occurredAt && lhs.createdAt == rhs.createdAt &&
        lhs.timeZoneIdentifier == rhs.timeZoneIdentifier && identicalNotes(lhs.note, rhs.note)
    }

    // String == accepts canonically equivalent Unicode sequences. Reconciliation
    // must instead compare the literal canonical payload, without normalizing interiors.
    static func identicalNotes(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case let (.some(lhs), .some(rhs)): return lhs.utf8.elementsEqual(rhs.utf8)
        default: return false
        }
    }
}
