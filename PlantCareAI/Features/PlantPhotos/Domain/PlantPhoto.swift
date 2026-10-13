import Foundation

struct PlantPhoto: Sendable, Equatable {
    let id: UUID
    let plantID: UUID
    let occurredAt: Date
    let createdAt: Date
    let timeZoneIdentifier: String
    let width: Int
    let height: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.plantID == rhs.plantID && lhs.occurredAt == rhs.occurredAt &&
        lhs.createdAt == rhs.createdAt && Array(lhs.timeZoneIdentifier.utf8) == Array(rhs.timeZoneIdentifier.utf8) &&
        lhs.width == rhs.width && lhs.height == rhs.height
    }
}

enum PlantPhotoError: Error, Equatable {
    case validation, plantNotFound, notFound, conflict, protectedIdentity, photoMissing, photoCorrupt, readFailure, storage
}

enum PlantPhotoIdentity: Hashable, Codable, Sendable {
    case initial(UUID), additional(UUID)

    var stableKey: String {
        switch self {
        case .initial(let id): return "initial-" + id.uuidString
        case .additional(let id): return "additional-" + id.uuidString
        }
    }
}

struct PlantPhotoDescriptor: Equatable, Sendable, Identifiable {
    let id: PlantPhotoIdentity
    let date: Date
    let createdAt: Date

    static func ordered(plant: Plant, photos: [PlantPhoto]) -> [Self] {
        ([Self(id: .initial(plant.id), date: plant.createdAt, createdAt: plant.createdAt)] +
         photos.filter { $0.plantID == plant.id }.map {
             Self(id: .additional($0.id), date: $0.occurredAt, createdAt: $0.createdAt)
         }).sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.stableKey < $1.id.stableKey
        }
    }
}
