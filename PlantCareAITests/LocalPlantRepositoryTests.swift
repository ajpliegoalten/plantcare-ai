import XCTest
import SwiftData
@testable import PlantCareAI

final class LocalPlantRepositoryTests: XCTestCase {
    var root: URL!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    func expect(_ expected: PlantStorageError, operation: () async throws -> Void) async {
        do { try await operation(); XCTFail("Expected \(expected)") }
        catch { XCTAssertEqual(error as? PlantStorageError, expected) }
    }

    func testTwoPlantsSurviveRecreationWithIndependentPhotosAndSheets() async throws {
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        for index in 1...2 {
            try await SavePlant(repository: repository!).execute(StorageTestFixture.plant(index), initialPhoto: StorageTestFixture.photo(index))
        }
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let plants = try await LoadPlants(repository: reopened).execute()
        XCTAssertEqual(plants, (1...2).map(StorageTestFixture.plant))
        for index in 1...2 {
            let bytes = try await LoadInitialPlantPhoto(repository: reopened).execute(for: StorageTestFixture.plant(index).id)
            XCTAssertEqual(bytes, StorageTestFixture.photo(index))
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("Photos").path)
        XCTAssertEqual(files.count, 2)
    }

    func testUpdatePreservesCompleteModelsPhotosAndReopensAndRejectsInvalidOrAbsent() async throws {
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let originals = (1...2).map(StorageTestFixture.plant)
        for index in 1...2 { try await repository!.savePlant(originals[index - 1], initialPhoto: StorageTestFixture.photo(index)) }
        let a = originals[0]
        let expected = Plant(id: a.id, name: "Mi monstera", confirmedSpecies: a.confirmedSpecies, createdAt: a.createdAt, location: "Salón", careSheet: a.careSheet)
        let result = try await repository!.updatePlant(id: a.id, name: " Mi monstera\n", location: " Salón ")
        XCTAssertEqual(result, expected)
        await expect(.validation) { _ = try await repository!.updatePlant(id: a.id, name: " \n", location: "Mutación") }
        await expect(.notFound) { _ = try await repository!.updatePlant(id: UUID(), name: "Otra", location: nil) }
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let plants = try await reopened.loadPlants(); XCTAssertEqual(plants, [expected, originals[1]])
        for index in 1...2 {
            let bytes = try await reopened.loadInitialPhoto(for: originals[index - 1].id)
            XCTAssertEqual(bytes, StorageTestFixture.photo(index))
        }
        let noLocation = try await reopened.updatePlant(id: a.id, name: expected.name, location: " \n")
        XCTAssertNil(noLocation.location)
        let added = try await reopened.updatePlant(id: originals[1].id, name: originals[1].name, location: "Patio")
        XCTAssertEqual(added.location, "Patio")
        let persistedOptional = try await LocalPlantRepository(root: root).loadPlants()
        XCTAssertEqual(persistedOptional, [noLocation, added])
        try FileManager.default.removeItem(at: root.appendingPathComponent("Photos/\(a.id).jpg"))
        _ = try await reopened.updatePlant(id: a.id, name: "Sin foto", location: nil)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("Photos/\(a.id).jpg").path))
    }

    func testUpdateFailureRollsBackBothFieldsInSameRepositoryAndReopenedAndCanRetry() async throws {
        let original = StorageTestFixture.plant(1)
        var seed: LocalPlantRepository? = LocalPlantRepository(root: root)
        try await seed!.savePlant(original, initialPhoto: StorageTestFixture.photo(1))
        seed = nil
        let fault = EditCommitFault()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeCommit: { try fault.check() })
        await expect(.storage) { _ = try await repository!.updatePlant(id: original.id, name: "Nuevo", location: "Nueva") }
        let rolledBack = try await repository!.loadPlants(); XCTAssertEqual(rolledBack, [original])
        fault.disable()
        let retry = try await repository!.updatePlant(id: original.id, name: "Reintento", location: "Patio")
        XCTAssertEqual(retry.name, "Reintento")
        // Restore original, then fail again to check failed values across recreation.
        _ = try await repository!.updatePlant(id: original.id, name: original.name, location: original.location)
        fault.enable()
        await expect(.storage) { _ = try await repository!.updatePlant(id: original.id, name: "Nuevo", location: "Nueva") }
        repository = nil
        var reopened: LocalPlantRepository? = LocalPlantRepository(root: root)
        let persisted = try await reopened!.loadPlants(); XCTAssertEqual(persisted, [original])
        reopened = nil
        fault.disable()
        repository = LocalPlantRepository(root: root, beforeCommit: { try fault.check() })
        let result = try await repository!.updatePlant(id: original.id, name: "Nuevo", location: "Nueva")
        XCTAssertEqual(result.name, "Nuevo"); XCTAssertEqual(result.location, "Nueva")
    }

    func testEmptyAndValidationAndDuplicateDoNotOverwrite() async throws {
        let repository = LocalPlantRepository(root: root)
        let empty = try await repository.loadPlants()
        XCTAssertTrue(empty.isEmpty)
        let plant = StorageTestFixture.plant(1)
        let invalid = Plant(id: plant.id, name: " ", confirmedSpecies: "", createdAt: plant.createdAt, location: nil, careSheet: plant.careSheet)
        await expect(.validation) { try await SavePlant(repository: repository).execute(invalid, initialPhoto: StorageTestFixture.photo(1)) }
        await expect(.validation) { try await SavePlant(repository: repository).execute(plant, initialPhoto: Data()) }
        let noSheet = Plant(id: plant.id, name: plant.name, confirmedSpecies: plant.confirmedSpecies,
                            createdAt: plant.createdAt, location: nil,
                            careSheet: CareSheet(light: "", watering: "", humidity: "", temperature: "", substrate: "", fertilizer: ""))
        await expect(.validation) { try await SavePlant(repository: repository).execute(noSheet, initialPhoto: StorageTestFixture.photo(1)) }
        await expect(.photoCorrupt) { try await SavePlant(repository: repository).execute(plant, initialPhoto: Data("not JPEG".utf8)) }
        try await SavePlant(repository: repository).execute(plant, initialPhoto: StorageTestFixture.photo(1))
        await expect(.duplicateID) { try await SavePlant(repository: repository).execute(plant, initialPhoto: StorageTestFixture.photo(2)) }
        let photo = try await repository.loadInitialPhoto(for: plant.id)
        XCTAssertEqual(photo, StorageTestFixture.photo(1))
    }

    func testMissingAndCorruptPhotoAreExplicitAndListDoesNotReadImages() async throws {
        let repository = LocalPlantRepository(root: root)
        let plant = StorageTestFixture.plant(1)
        try await repository.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let path = root.appendingPathComponent("Photos/\(plant.id.uuidString).jpg")
        try FileManager.default.removeItem(at: path)
        let plants = try await repository.loadPlants()
        XCTAssertEqual(plants, [plant]) // Metadata listing does not touch binaries.
        await expect(.photoMissing) { _ = try await repository.loadInitialPhoto(for: plant.id) }
        try Data("broken".utf8).write(to: path)
        await expect(.photoCorrupt) { _ = try await repository.loadInitialPhoto(for: plant.id) }
    }

    func testFailedCommitCompensatesAndStartupCleansOrphans() async throws {
        let repository = LocalPlantRepository(root: root, beforeCommit: { throw PlantStorageError.storage })
        await expect(.storage) { try await repository.savePlant(StorageTestFixture.plant(1), initialPhoto: StorageTestFixture.photo(1)) }
        let plants = try await repository.loadPlants()
        XCTAssertTrue(plants.isEmpty)
        let photos = root.appendingPathComponent("Photos")
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: photos.path).isEmpty)
        try StorageTestFixture.photo(1).write(to: photos.appendingPathComponent("orphan.jpg"))
        try Data().write(to: photos.appendingPathComponent("interrupted.pending"))
        let reopened = LocalPlantRepository(root: root)
        _ = try await reopened.loadPlants()
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: photos.path).isEmpty)
    }

    func testUnreadableSwiftDataStoreIsNotEmpty() async throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("invalid".utf8).write(to: root.appendingPathComponent("Plants.store"))
        let repository = LocalPlantRepository(root: root)
        await expect(.storage) { _ = try await repository.loadPlants() }
    }

    func testInvalidPersistedRecordFailsWithoutCleaningPhotos() async throws {
        // Simulate readable SwiftData with invalid domain fields, not just a broken database header.
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let container = try ModelContainer(for: PersistedPlant.self,
                                          configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        let record = PersistedPlant(StorageTestFixture.plant(1))
        record.light = ""
        context.insert(record)
        try context.save()
        let photos = root.appendingPathComponent("Photos")
        try FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
        try StorageTestFixture.photo(1).write(to: photos.appendingPathComponent("preserved.jpg"))
        let repository = LocalPlantRepository(root: root)
        await expect(.storage) { _ = try await repository.loadPlants() }
        XCTAssertTrue(FileManager.default.fileExists(atPath: photos.appendingPathComponent("preserved.jpg").path))
    }
}

private final class EditCommitFault: @unchecked Sendable {
    private let lock = NSLock()
    private var fails = true
    func check() throws { lock.lock(); defer { lock.unlock() }; if fails { throw PlantStorageError.storage } }
    func disable() { lock.lock(); defer { lock.unlock() }; fails = false }
    func enable() { lock.lock(); defer { lock.unlock() }; fails = true }
}
