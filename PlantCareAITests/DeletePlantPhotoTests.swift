import XCTest
import SwiftData
@testable import PlantCareAI

final class DeletePlantPhotoTests: XCTestCase {
    func testPreSaveFailureWithMissingOrCorruptJPEGRetainsUnknownImageWithoutTouchingOtherFiles() async throws {
        for missing in [true, false] {
            let directory = root.appendingPathComponent(UUID().uuidString)
            var seed: LocalPlantRepository? = LocalPlantRepository(root: directory)
            let fixture = try await HistoryDeletionSeed.make(seed!); seed = nil
            let file = directory.appendingPathComponent("AdditionalPhotos/\(fixture.photo.id).jpg")
            if missing { try FileManager.default.removeItem(at: file) }
            else { try Data("broken".utf8).write(to: file) }
            let repository = LocalPlantRepository(root: directory, beforeDeletionCommit: { throw PlantPhotoError.storage })
            do { _ = try await repository.deletePhoto(fixture.photo); XCTFail() }
            catch { XCTAssertEqual(error as? PlantPhotoError, .storage) }
            let photos = try await repository.loadPhotos(for: fixture.plant.id); XCTAssertEqual(photos, [fixture.photo])
            XCTAssertEqual(FileManager.default.fileExists(atPath: file.path), !missing)
            if !missing { XCTAssertEqual(try Data(contentsOf: file), Data("broken".utf8)) }
            let otherJPEG = try await repository.loadPhoto(id: fixture.otherPhoto.id, for: fixture.other.id)
            XCTAssertEqual(otherJPEG, fixture.jpeg)
            let initial = try await repository.loadInitialPhoto(for: fixture.plant.id); XCTAssertEqual(initial, StorageTestFixture.photo(1))
        }
    }
    func testCleanupOrphanWaitsForValidationOfAllEntitiesOnReopen() async throws {
        var seed: LocalPlantRepository? = LocalPlantRepository(root: root)
        let fixture = try await HistoryDeletionSeed.make(seed!); seed = nil
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCleanup: { throw PlantPhotoError.storage })
        _ = try await repository!.deletePhoto(fixture.photo); repository = nil
        try corruptCareMetadata()
        do { _ = try await LocalPlantRepository(root: root).loadPlants(); XCTFail() }
        catch { XCTAssertEqual(error as? PlantStorageError, .storage) }
        XCTAssertEqual(try Data(contentsOf: file(fixture.photo)), fixture.jpeg)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("Photos/\(fixture.plant.id).jpg")), StorageTestFixture.photo(1))
    }
    private func corruptCareMetadata() throws {
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self,
            configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        try context.fetch(FetchDescriptor<PersistedCareEvent>())[0].kind = "unknown"
        try context.save()
    }
    private var root: URL!
    override func setUp() { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
    override func tearDown() { try? FileManager.default.removeItem(at: root) }

    func testInitialRejectedBeforeWriterAndMismatchedAdditionalRejected() async throws {
        let writer = DeletionPhotoSpy(), photo = PlantTimelineFixtureLoad.photo(for: UUID())
        let useCase = DeletePlantPhoto(repository: writer)
        for initialID in [photo.plantID, photo.id] {
            do { _ = try await useCase.execute(.initial(initialID), expected: photo); XCTFail() }
            catch { XCTAssertEqual(error as? PlantPhotoError, .protectedIdentity) }
        }
        do { _ = try await useCase.execute(.additional(UUID()), expected: photo); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .conflict) }
        let count = await writer.count; XCTAssertEqual(count, 0)
        let result = try await useCase.execute(.additional(photo.id), expected: photo); XCTAssertEqual(result, photo)
        let finalCount = await writer.count; XCTAssertEqual(finalCount, 1)
    }

    func testDeleteReopenRemovesJPEGOnlyOwnAdditionalNotMatchingCareUUID() async throws {
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let fixture = try await HistoryDeletionSeed.make(repository!)
        let removed = try await DeletePlantPhoto(repository: repository!).execute(.additional(fixture.photo.id), expected: fixture.photo)
        XCTAssertEqual(removed, fixture.photo)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file(fixture.photo).path))
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        try await fixture.assertUnchanged(reopened, deletedPhoto: true)
        let events = try await reopened.loadCareEvents(for: fixture.plant.id)
        XCTAssertEqual(Set(events.map(\.id)), Set(fixture.events.map(\.id)))
        for event in events { XCTAssertTrue(fixture.events.contains(event)) }
        do { _ = try await reopened.loadPhoto(id: fixture.photo.id, for: fixture.plant.id); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .notFound) }
    }

    func testPreSaveRollbackKeepsExactMetadataJPEGMemoryAndReopen() async throws {
        var seed: LocalPlantRepository? = LocalPlantRepository(root: root)
        let fixture = try await HistoryDeletionSeed.make(seed!); seed = nil
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCommit: { throw PlantPhotoError.storage })
        do { _ = try await repository!.deletePhoto(fixture.photo); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .storage) }
        try await fixture.assertUnchanged(repository!)
        XCTAssertEqual(try Data(contentsOf: file(fixture.photo)), fixture.jpeg)
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        try await fixture.assertUnchanged(reopened)
        _ = try await reopened.deletePhoto(fixture.photo)
        try await fixture.assertUnchanged(reopened, deletedPhoto: true)
    }

    func testPostCommitCleanupFailureIsSuccessAndReopenRecoversOrphan() async throws {
        var seed: LocalPlantRepository? = LocalPlantRepository(root: root)
        let fixture = try await HistoryDeletionSeed.make(seed!); seed = nil
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCleanup: { throw PlantPhotoError.storage })
        let removed = try await repository!.deletePhoto(fixture.photo); XCTAssertEqual(removed, fixture.photo)
        try await fixture.assertUnchanged(repository!, deletedPhoto: true)
        XCTAssertEqual(try Data(contentsOf: file(fixture.photo)), fixture.jpeg)
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        try await fixture.assertUnchanged(reopened, deletedPhoto: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file(fixture.photo).path))
    }

    func testAbsentOrCorruptJPEGDoesNotPreventOwnMetadataDeletion() async throws {
        for missing in [true, false] {
            let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
            if missing { try FileManager.default.removeItem(at: file(fixture.photo)) }
            else { try Data("broken".utf8).write(to: file(fixture.photo)) }
            _ = try await repository.deletePhoto(fixture.photo)
            try await fixture.assertUnchanged(repository, deletedPhoto: true)
            try FileManager.default.removeItem(at: root)
        }
    }

    func testForeignConflictDuplicateAndInitialUUIDWithoutAdditionalCannotTouchInitial() async throws {
        let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
        for (id, plantID) in [(fixture.photo.id, fixture.other.id), (fixture.plant.id, fixture.plant.id)] {
            let expected = PlantPhoto(id: id, plantID: plantID, occurredAt: fixture.photo.occurredAt,
                createdAt: fixture.photo.createdAt, timeZoneIdentifier: fixture.photo.timeZoneIdentifier, width: 640, height: 480)
            do { _ = try await repository.deletePhoto(expected); XCTFail() }
            catch { XCTAssertEqual(error as? PlantPhotoError, .notFound) }
        }
        let changed = PlantPhoto(id: fixture.photo.id, plantID: fixture.photo.plantID, occurredAt: fixture.photo.occurredAt,
            createdAt: fixture.photo.createdAt, timeZoneIdentifier: "Europe/Madrid", width: 640, height: 480)
        do { _ = try await repository.deletePhoto(changed); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .conflict) }
        try await fixture.assertUnchanged(repository)
        _ = try await repository.deletePhoto(fixture.photo)
        do { _ = try await repository.deletePhoto(fixture.photo); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .notFound) }
    }
    private func file(_ photo: PlantPhoto) -> URL { root.appendingPathComponent("AdditionalPhotos/\(photo.id).jpg") }
}

private actor DeletionPhotoSpy: PlantPhotoDeletingRepository {
    var count = 0
    func deletePhoto(_ expected: PlantPhoto) async throws -> PlantPhoto { count += 1; return expected }
}
