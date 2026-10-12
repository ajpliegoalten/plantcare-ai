import Foundation

enum PlantTimelineIdentity: Hashable, Sendable {
    case care(UUID), additional(UUID), initial(UUID)

    var stableKey: String {
        switch self {
        case .care(let id): return "care-" + id.uuidString
        case .additional(let id): return "additional-" + id.uuidString
        case .initial(let id): return "initial-" + id.uuidString
        }
    }
}

// A read projection, never a second persisted history or a copy of JPEG bytes.
enum PlantTimelineEntry: Equatable, Sendable, Identifiable {
    case care(CareEvent), additional(PlantPhoto), initial(Plant)

    var id: PlantTimelineIdentity {
        switch self {
        case .care(let event): return .care(event.id)
        case .additional(let photo): return .additional(photo.id)
        case .initial(let plant): return .initial(plant.id)
        }
    }
    var plantID: UUID {
        switch self {
        case .care(let event): return event.plantID
        case .additional(let photo): return photo.plantID
        case .initial(let plant): return plant.id
        }
    }
    var elementDate: Date {
        switch self {
        case .care(let event): return event.occurredAt
        case .additional(let photo): return photo.occurredAt
        case .initial(let plant): return plant.createdAt
        }
    }
    var createdAt: Date {
        switch self {
        case .care(let event): return event.createdAt
        case .additional(let photo): return photo.createdAt
        case .initial(let plant): return plant.createdAt
        }
    }
    var isPhoto: Bool { if case .care = self { return false }; return true }
}
