import XCTest
import SwiftData
import ImageIO
@testable import PlantCareAI

final class LocalPlantPhotoRepositoryTests: XCTestCase {
    private var root: URL!
    private var jpeg: Data!
    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        jpeg = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1)).jpeg
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    private func record(id: UUID = UUID(), plant: Int = 1, day: Int = 2) throws -> PlantPhoto {
        let source = CGImageSourceCreateWithData(jpeg as CFData, nil)!
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)! as NSDictionary
        return PlantPhoto(id: id, plantID: StorageTestFixture.plant(plant).id,
            occurredAt: try AddPlantPhoto.startOfDay(year: 2020, month: 1, day: day, zone: try AddPlantPhoto.zone("Europe/Madrid")),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000), timeZoneIdentifier: "Europe/Madrid",
            width: properties[kCGImagePropertyPixelWidth] as! Int, height: properties[kCGImagePropertyPixelHeight] as! Int)
    }

    private func seed(v2: Bool) throws -> [CareEvent] {
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Photos"), withIntermediateDirectories: true)
        let configuration = ModelConfiguration(url: root.appendingPathComponent("Plants.store"))
        let container = v2 ? try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, configurations: configuration)
                           : try ModelContainer(for: PersistedPlant.self, configurations: configuration)
        let context = ModelContext(container); context.autosaveEnabled = false
        for index in 1...2 {
            context.insert(PersistedPlant(StorageTestFixture.plant(index)))
            try StorageTestFixture.photo(index).write(to: root.appendingPathComponent("Photos/\(StorageTestFixture.plant(index).id).jpg"))
        }
        var events: [CareEvent] = []
        if v2 {
            for (index, kind) in CareEvent.Kind.allCases.enumerated() {
                let event = CareEvent(id: UUID(), plantID: StorageTestFixture.plant(index % 2 + 1).id, kind: kind,
                    occurredAt: try record().occurredAt, note: "e\u{301}\n🌿 \(kind.rawValue)",
                    createdAt: Date(timeIntervalSince1970: 1_700_000_000), timeZoneIdentifier: "Europe/Madrid")
                events.append(event); context.insert(PersistedCareEvent(event))
            }
        }
        try context.save()
        return events
    } // Real old containers released before the V3 actor opens.

    func testRealV2AndV1UpgradeRoundtripSevenFieldsBytesFiveKindsAndIsolation() async throws {
        for v2 in [true, false] {
            let old = try seed(v2: v2)
            var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
            let first = try record(), second = try record(), other = try record(plant: 2, day: 1)
            for photo in [first, second, other] {
                let confirmed = try await repository!.savePhoto(photo, jpeg: jpeg)
                XCTAssertEqual(confirmed, photo)
            }
            repository = nil
            var reopened: LocalPlantRepository? = LocalPlantRepository(root: root)
            let plants = try await reopened!.loadPlants(); XCTAssertEqual(plants, (1...2).map(StorageTestFixture.plant))
            for index in 1...2 {
                let id = StorageTestFixture.plant(index).id
                let initial = try await reopened!.loadInitialPhoto(for: id); XCTAssertEqual(initial, StorageTestFixture.photo(index))
                let photos = try await reopened!.loadPhotos(for: id)
                XCTAssertEqual(Set(photos.map(\.id)), Set((index == 1 ? [first, second] : [other]).map(\.id)))
                let events = try await reopened!.loadCareEvents(for: id)
                XCTAssertEqual(Set(events.map(\.id)), Set(old.filter { $0.plantID == id }.map(\.id)))
                for event in events { XCTAssertTrue(old.contains(event)) }
                for photo in photos {
                    XCTAssertTrue([first, second, other].contains(photo))
                    let actualJPEG = try await reopened!.loadPhoto(id: photo.id, for: id); XCTAssertEqual(actualJPEG, jpeg)
                }
            }
            reopened = nil
            try FileManager.default.removeItem(at: root)
        }
    }

    func testRollbackAtEverySeamRetryDuplicateBeforeClockAndConflicts() async throws {
        _ = try seed(v2: true)
        let photo = try record()
        for stage in 0...2 {
            var repository: LocalPlantRepository? = LocalPlantRepository(root: root,
                photoPublication: { _, published in if (stage == 0 && !published) || (stage == 1 && published) { throw PlantPhotoError.storage } },
                beforePhotoCommit: { _ in if stage == 2 { throw PlantPhotoError.storage } })
            do { _ = try await repository!.savePhoto(photo, jpeg: jpeg); XCTFail() }
            catch { XCTAssertEqual(error as? PlantPhotoError, .storage) }
            let empty = try await repository!.loadPhotos(for: photo.plantID); XCTAssertTrue(empty.isEmpty)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("AdditionalPhotos").path), [])
            repository = nil
        }
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        _ = try await repository!.savePhoto(photo, jpeg: jpeg); repository = nil
        let backward = LocalPlantRepository(root: root, now: { photo.occurredAt.addingTimeInterval(-1) })
        let duplicate = try await backward.savePhoto(photo, jpeg: jpeg); XCTAssertEqual(duplicate, photo)
        let conflict = PlantPhoto(id: photo.id, plantID: photo.plantID, occurredAt: photo.occurredAt, createdAt: photo.createdAt,
                                  timeZoneIdentifier: "Europe/Paris", width: photo.width, height: photo.height)
        do { _ = try await backward.savePhoto(conflict, jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .conflict) }
        do { _ = try await backward.savePhoto(try record(), jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .validation) }
        let actual = try await backward.loadPhotos(for: photo.plantID); XCTAssertEqual(actual, [photo])
    }

    func testRecoveryReferencesMissingCorruptMetadataAndCrossPlantRead() async throws {
        _ = try seed(v2: true)
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let photo = try record(); _ = try await repository!.savePhoto(photo, jpeg: jpeg)
        repository = nil
        let directory = root.appendingPathComponent("AdditionalPhotos")
        for name in ["orphan.jpg", "interrupted.pending", "keep.txt"] { try Data("keep".utf8).write(to: directory.appendingPathComponent(name)) }
        repository = LocalPlantRepository(root: root)
        let actual = try await repository!.loadPhotos(for: photo.plantID); XCTAssertEqual(actual, [photo])
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("orphan.jpg").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("interrupted.pending").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("keep.txt").path))
        do { _ = try await repository!.loadPhoto(id: photo.id, for: StorageTestFixture.plant(2).id); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .notFound) }
        let file = directory.appendingPathComponent(photo.id.uuidString + ".jpg")
        try FileManager.default.removeItem(at: file)
        do { _ = try await repository!.loadPhoto(id: photo.id, for: photo.plantID); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .photoMissing) }
        try Data("broken".utf8).write(to: file)
        do { _ = try await repository!.loadPhoto(id: photo.id, for: photo.plantID); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .photoCorrupt) }
        try StorageTestFixture.photo(1).write(to: file) // A decodable original with excluded metadata is not prepared storage.
        do { _ = try await repository!.loadPhoto(id: photo.id, for: photo.plantID); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .photoCorrupt) }
        repository = nil
        try corruptReference()
        for path in ["Photos/keep.pending", "AdditionalPhotos/keep.pending"] { try Data("keep".utf8).write(to: root.appendingPathComponent(path)) }
        let unreadable = LocalPlantRepository(root: root)
        do { _ = try await unreadable.loadPhotos(for: photo.plantID); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .storage) }
        for path in ["Photos/keep.pending", "AdditionalPhotos/keep.pending"] { XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(path)), Data("keep".utf8)) }
    }

    private func corruptReference() throws {
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self,
                                          configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        try context.fetch(FetchDescriptor<PersistedPlantPhoto>())[0].photoReference = "../outside.jpg"
        try context.save()
    }
    func testDirectCallersRejectFutureCorruptDimensionsMissingPlantAndNeverOverwriteExistingFile() async throws {
        _ = try seed(v2: true)
        let repository = LocalPlantRepository(root: root)
        let original = try record()
        _ = try await repository.loadPlants() // Open/recover before creating a preexisting destination.
        let destination = root.appendingPathComponent("AdditionalPhotos/\(original.id).jpg")
        let preexisting = Data("must not overwrite".utf8); try preexisting.write(to: destination)
        do { _ = try await repository.savePhoto(original, jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .storage) }
        XCTAssertEqual(try Data(contentsOf: destination), preexisting)
        try FileManager.default.removeItem(at: destination)
        do { _ = try await repository.savePhoto(original, jpeg: Data("broken".utf8)); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .photoCorrupt) }
        let wrongDimensions = PlantPhoto(id: original.id, plantID: original.plantID, occurredAt: original.occurredAt,
            createdAt: original.createdAt, timeZoneIdentifier: original.timeZoneIdentifier, width: original.width - 1, height: original.height)
        do { _ = try await repository.savePhoto(wrongDimensions, jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .photoCorrupt) }
        let missingPlant = PlantPhoto(id: original.id, plantID: UUID(), occurredAt: original.occurredAt, createdAt: original.createdAt,
            timeZoneIdentifier: original.timeZoneIdentifier, width: original.width, height: original.height)
        do { _ = try await repository.savePhoto(missingPlant, jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .plantNotFound) }
        let future = PlantPhoto(id: original.id, plantID: original.plantID,
            occurredAt: AddPlantPhoto.calendar(in: try AddPlantPhoto.zone(original.timeZoneIdentifier)).startOfDay(for: Date().addingTimeInterval(2 * 86400)),
            createdAt: original.createdAt, timeZoneIdentifier: original.timeZoneIdentifier, width: original.width, height: original.height)
        do { _ = try await repository.savePhoto(future, jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .validation) }
        let empty = try await repository.loadPhotos(for: original.plantID); XCTAssertTrue(empty.isEmpty)
    }
}
