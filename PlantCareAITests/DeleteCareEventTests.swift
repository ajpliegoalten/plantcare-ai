import XCTest
@testable import PlantCareAI

final class DeleteCareEventTests: XCTestCase {
    func testUnreadableStoreIsReadFailureNotRollbackGuarantee() async throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("broken".utf8).write(to: root.appendingPathComponent("Plants.store"))
        let event = PlantTimelineFixtureLoad.events(for: StorageTestFixture.plant(1).id)[0]
        do { _ = try await LocalPlantRepository(root: root).deleteCareEvent(event); XCTFail() }
        catch { XCTAssertEqual(error as? CareEventError, .readFailure) }
    }
    private var root: URL!
    override func setUp() { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
    override func tearDown() { try? FileManager.default.removeItem(at: root) }

    func testFiveTypesDeleteOnlyExpectedSnapshotAndReopenExactOtherEntities() async throws {
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let fixture = try await HistoryDeletionSeed.make(repository!)
        for event in fixture.events {
            let confirmed = try await DeleteCareEvent(repository: repository!).execute(event)
            XCTAssertEqual(confirmed, event)
            let remaining = try await repository!.loadCareEvents(for: fixture.plant.id)
            XCTAssertFalse(remaining.contains(event))
        }
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let events = try await reopened.loadCareEvents(for: fixture.plant.id)
        XCTAssertEqual(events, [])
        try await fixture.assertUnchanged(reopened)
    }

    func testRollbackAfterMutationPreservesMemoryDiskNoteAndRetryUsesSameSnapshot() async throws {
        var seed: LocalPlantRepository? = LocalPlantRepository(root: root)
        let fixture = try await HistoryDeletionSeed.make(seed!); seed = nil
        let fault = HistoryDeletionTestFixture(mode: "failOnce")
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCommit: { try fault.beforeCommit() })
        let event = fixture.events[2]
        do { _ = try await repository!.deleteCareEvent(event); XCTFail() }
        catch { XCTAssertEqual(error as? CareEventError, .storage) }
        let memory = try await repository!.loadCareEvents(for: fixture.plant.id)
        XCTAssertEqual(Set(memory.map(\.id)), Set(fixture.events.map(\.id))); XCTAssertTrue(memory.contains(event))
        try await fixture.assertUnchanged(repository!)
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let disk = try await reopened.loadCareEvents(for: fixture.plant.id)
        XCTAssertEqual(memory, disk)
        let removed = try await reopened.deleteCareEvent(event); XCTAssertEqual(removed, event)
        let final = try await reopened.loadCareEvents(for: fixture.plant.id)
        XCTAssertEqual(final, disk.filter { $0.id != event.id })
        try await fixture.assertUnchanged(reopened)
    }

    func testConflictForeignMissingAndDuplicateNeverDeleteDifferentPayload() async throws {
        let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
        let event = fixture.events[0]
        for expected in [
            CareEvent(id: event.id, plantID: fixture.other.id, kind: event.kind, occurredAt: event.occurredAt, note: event.note, createdAt: event.createdAt, timeZoneIdentifier: event.timeZoneIdentifier),
            CareEvent(id: UUID(), plantID: fixture.plant.id, kind: event.kind, occurredAt: event.occurredAt, note: event.note, createdAt: event.createdAt, timeZoneIdentifier: event.timeZoneIdentifier)
        ] {
            do { _ = try await repository.deleteCareEvent(expected); XCTFail() }
            catch { XCTAssertEqual(error as? CareEventError, .notFound) }
        }
        let changed = CareEvent(id: event.id, plantID: event.plantID, kind: event.kind, occurredAt: event.occurredAt,
            note: event.note! + "changed", createdAt: event.createdAt, timeZoneIdentifier: event.timeZoneIdentifier)
        do { _ = try await repository.deleteCareEvent(changed); XCTFail() }
        catch { XCTAssertEqual(error as? CareEventError, .conflict) }
        _ = try await repository.deleteCareEvent(event)
        do { _ = try await repository.deleteCareEvent(event); XCTFail() }
        catch { XCTAssertEqual(error as? CareEventError, .notFound) }
        try await fixture.assertUnchanged(repository)
    }

    func testLastWateringRecalculatesMaxTieRemainingAndTrueAbsence() async throws {
        let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
        let first = fixture.events[0]
        let later = CareEvent(id: UUID(), plantID: first.plantID, kind: .watering, occurredAt: first.occurredAt.addingTimeInterval(86400),
            note: nil, createdAt: first.createdAt, timeZoneIdentifier: first.timeZoneIdentifier)
        let tie = CareEvent(id: UUID(), plantID: first.plantID, kind: .watering, occurredAt: later.occurredAt,
            note: nil, createdAt: first.createdAt, timeZoneIdentifier: first.timeZoneIdentifier)
        _ = try await repository.saveCareEvent(later); _ = try await repository.saveCareEvent(tie)
        for (event, expected) in [(fixture.events[1], later.occurredAt as Date?), (tie, later.occurredAt), (later, first.occurredAt), (first, nil)] {
            _ = try await repository.deleteCareEvent(event)
            let actual = try await LoadLastWatering(repository: repository).execute(for: first.plantID)
            XCTAssertEqual(actual, expected)
        }
    }
}

struct HistoryDeletionSeed {
    let plant = StorageTestFixture.plant(1), other = StorageTestFixture.plant(2)
    let events: [CareEvent]
    let sentinel: CareEvent
    let photo: PlantPhoto
    let otherPhoto: PlantPhoto
    let jpeg: Data
    static func make(_ repository: LocalPlantRepository) async throws -> Self {
        for index in 1...2 { try await repository.savePlant(StorageTestFixture.plant(index), initialPhoto: StorageTestFixture.photo(index)) }
        let events = PlantTimelineFixtureLoad.events(for: StorageTestFixture.plant(1).id)
        for event in events { _ = try await repository.saveCareEvent(event) }
        let sentinel = CareEvent(id: UUID(), plantID: StorageTestFixture.plant(2).id, kind: .watering,
            occurredAt: Date(timeIntervalSince1970: 172800), note: "Otra planta\ne\u{301}", createdAt: Date(timeIntervalSince1970: 300000), timeZoneIdentifier: "Africa/Abidjan")
        _ = try await repository.saveCareEvent(sentinel)
        // Deliberate collision: entity identities must not be interchangeable.
        let photo = PlantPhoto(id: events[0].id, plantID: events[0].plantID, occurredAt: events[0].occurredAt,
            createdAt: events[0].createdAt, timeZoneIdentifier: events[0].timeZoneIdentifier, width: 640, height: 480)
        let otherPhoto = PlantPhoto(id: UUID(), plantID: sentinel.plantID, occurredAt: sentinel.occurredAt,
            createdAt: sentinel.createdAt, timeZoneIdentifier: sentinel.timeZoneIdentifier, width: 640, height: 480)
        let jpeg = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2)).jpeg
        for photo in [photo, otherPhoto] { _ = try await repository.savePhoto(photo, jpeg: jpeg) }
        return Self(events: events, sentinel: sentinel, photo: photo, otherPhoto: otherPhoto, jpeg: jpeg)
    }
    func assertUnchanged(_ repository: LocalPlantRepository, deletedPhoto: Bool = false) async throws {
        let plants = try await repository.loadPlants(); XCTAssertEqual(plants, [plant, other])
        for index in 1...2 {
            let bytes = try await repository.loadInitialPhoto(for: StorageTestFixture.plant(index).id)
            XCTAssertEqual(bytes, StorageTestFixture.photo(index))
        }
        let otherEvents = try await repository.loadCareEvents(for: other.id); XCTAssertEqual(otherEvents, [sentinel])
        let ownPhotos = try await repository.loadPhotos(for: plant.id); XCTAssertEqual(ownPhotos, deletedPhoto ? [] : [photo])
        let otherPhotos = try await repository.loadPhotos(for: other.id); XCTAssertEqual(otherPhotos, [otherPhoto])
        for photo in deletedPhoto ? [otherPhoto] : [photo, otherPhoto] {
            let bytes = try await repository.loadPhoto(id: photo.id, for: photo.plantID); XCTAssertEqual(bytes, jpeg)
        }
    }
}
