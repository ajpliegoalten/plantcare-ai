import XCTest
@testable import PlantCareAI

final class AddPlantPhotoTests: XCTestCase {
    func testCivilDateDSTSkippedDayInvalidZoneNonFiniteAndFuture() throws {
        let zone = try AddPlantPhoto.zone("Europe/Madrid")
        let day = try AddPlantPhoto.startOfDay(year: 2024, month: 3, day: 31, zone: zone)
        let next = try AddPlantPhoto.startOfDay(year: 2024, month: 4, day: 1, zone: zone)
        XCTAssertEqual(next.timeIntervalSince(day), 23 * 3600)
        XCTAssertThrowsError(try AddPlantPhoto.startOfDay(year: 2011, month: 12, day: 30, zone: try AddPlantPhoto.zone("Pacific/Apia")))
        XCTAssertThrowsError(try AddPlantPhoto.zone("Invalid/Zone"))
        XCTAssertThrowsError(try AddPlantPhoto.zone("GMT"))
        func photo(_ date: Date, width: Int = 640) -> PlantPhoto {
            PlantPhoto(id: UUID(), plantID: UUID(), occurredAt: date, createdAt: day,
                       timeZoneIdentifier: zone.identifier, width: width, height: 480)
        }
        XCTAssertNoThrow(try AddPlantPhoto.validateInsertion(photo(day), now: next))
        XCTAssertThrowsError(try AddPlantPhoto.validateInsertion(photo(next), now: day))
        XCTAssertThrowsError(try AddPlantPhoto.validateStructure(photo(day.addingTimeInterval(1))))
        XCTAssertThrowsError(try AddPlantPhoto.validateStructure(photo(Date(timeIntervalSinceReferenceDate: .infinity))))
        XCTAssertThrowsError(try AddPlantPhoto.validateStructure(photo(day, width: 2049)))
    }
}

final class LoadPlantPhotosTests: XCTestCase {
    func testInitialProjectedOnceDiscriminatedCollisionStableAbsoluteOrder() throws {
        let plant = StorageTestFixture.plant(1)
        let photo = PlantPhoto(id: plant.id, plantID: plant.id, occurredAt: plant.createdAt.addingTimeInterval(-1),
            createdAt: plant.createdAt.addingTimeInterval(20), timeZoneIdentifier: "Europe/Madrid", width: 1, height: 1)
        let newest = PlantPhoto(id: UUID(), plantID: plant.id, occurredAt: plant.createdAt.addingTimeInterval(-1000),
            createdAt: photo.createdAt.addingTimeInterval(1), timeZoneIdentifier: photo.timeZoneIdentifier, width: 1, height: 1)
        let result = PlantPhotoDescriptor.ordered(plant: plant, photos: [photo, newest])
        XCTAssertEqual(result.map(\.id), [.initial(plant.id), .additional(photo.id), .additional(newest.id)])
        XCTAssertEqual(result.last?.date, newest.occurredAt) // Human date is displayed, never used for ordering.
        XCTAssertEqual(Set(result.map(\.id)).count, 3)
    }

    func testCreationOrderIsStableForTiesRegardlessOfHumanDateAndInputOrder() {
        let plant = StorageTestFixture.plant(1)
        let ids = [UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                   UUID(uuidString: "00000000-0000-0000-0000-000000000002")!]
        let photos = ids.enumerated().map { index, id in
            PlantPhoto(id: id, plantID: plant.id, occurredAt: plant.createdAt.addingTimeInterval(Double(-index - 1)),
                createdAt: plant.createdAt.addingTimeInterval(1), timeZoneIdentifier: "Europe/Madrid", width: 1, height: 1)
        }
        XCTAssertEqual(PlantPhotoDescriptor.ordered(plant: plant, photos: photos.reversed()).map(\.id),
            [.initial(plant.id), .additional(ids[0]), .additional(ids[1])])
    }
}
