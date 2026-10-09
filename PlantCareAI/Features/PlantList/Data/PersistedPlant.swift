import Foundation
import SwiftData

@Model
final class PersistedPlant {
    @Attribute(.unique) var id: UUID
    var name: String
    var confirmedSpecies: String
    var createdAt: Date
    var location: String?
    var photoReference: String
    var light: String
    var watering: String
    var humidity: String
    var temperature: String
    var substrate: String
    var fertilizer: String

    init(_ plant: Plant) {
        id = plant.id
        name = plant.name
        confirmedSpecies = plant.confirmedSpecies
        createdAt = plant.createdAt
        location = plant.location
        photoReference = plant.id.uuidString + ".jpg"
        light = plant.careSheet.light
        watering = plant.careSheet.watering
        humidity = plant.careSheet.humidity
        temperature = plant.careSheet.temperature
        substrate = plant.careSheet.substrate
        fertilizer = plant.careSheet.fertilizer
    }

    func domain() throws -> Plant {
        let plant = Plant(id: id, name: name, confirmedSpecies: confirmedSpecies,
                          createdAt: createdAt, location: location,
                          careSheet: CareSheet(light: light, watering: watering, humidity: humidity,
                                               temperature: temperature, substrate: substrate, fertilizer: fertilizer))
        try SavePlant.validate(plant)
        guard photoReference == id.uuidString + ".jpg" else { throw PlantStorageError.storage }
        return plant
    }
}
