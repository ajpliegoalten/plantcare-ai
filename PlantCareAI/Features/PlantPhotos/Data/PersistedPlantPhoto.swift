import Foundation
import SwiftData

@Model
final class PersistedPlantPhoto {
    @Attribute(.unique) var id: UUID
    var plantID: UUID
    var occurredAt: Date
    var createdAt: Date
    var timeZoneIdentifier: String
    var width: Int
    var height: Int
    var photoReference: String

    init(_ photo: PlantPhoto) {
        id = photo.id; plantID = photo.plantID; occurredAt = photo.occurredAt
        createdAt = photo.createdAt; timeZoneIdentifier = photo.timeZoneIdentifier
        width = photo.width; height = photo.height; photoReference = photo.id.uuidString + ".jpg"
    }

    func domain() throws -> PlantPhoto {
        let photo = PlantPhoto(id: id, plantID: plantID, occurredAt: occurredAt, createdAt: createdAt,
                              timeZoneIdentifier: timeZoneIdentifier, width: width, height: height)
        try AddPlantPhoto.validateStructure(photo)
        guard photoReference == id.uuidString + ".jpg" else { throw PlantPhotoError.storage }
        return photo
    }
}
