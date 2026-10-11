import XCTest
@testable import PlantCareAI

struct CreationPhotoValidator: PreparedPlantPhotoValidating {
    func validate(_ photo: IdentificationPhoto) async throws {}
}

private final class CreationCommitFault: @unchecked Sendable {
    private let lock = NSLock()
    private var enabled = true
    func check() throws {
        lock.lock(); defer { lock.unlock() }
        if enabled { throw PlantStorageError.storage }
    }
    func disable() { lock.lock(); enabled = false; lock.unlock() }
}

final class SaveConfirmedPlantTests: XCTestCase {
    func snapshot(photo: IdentificationPhoto, source: ConfirmedDraftIdentity.Source = .manual(name: " Ficus 🌱 "), id: UUID = UUID()) -> ConfirmedPlantSnapshot {
        ConfirmedPlantSnapshot(id: id, createdAt: Date(timeIntervalSince1970: 123), photo: photo,
            identity: ConfirmedDraftIdentity(photoID: photo.id, source: source),
            careSheet: CareSheet(light: " Luz ", watering: "Riego", humidity: "Humedad", temperature: "Temperatura", substrate: "Sustrato", fertilizer: "Abonado"))
    }

    func testMappingNamesManualAndAIExactUnicodeNoLocation() throws {
        let photo = IdentificationPhoto(id: UUID(), jpeg: Data([1]), width: 1, height: 1)
        let manual = try snapshot(photo: photo).plant()
        XCTAssertEqual(manual.name, "Ficus 🌱"); XCTAssertEqual(manual.confirmedSpecies, manual.name)
        XCTAssertNil(manual.location); XCTAssertEqual(manual.careSheet.light, "Luz")
        for (common, scientific, name, species) in [("Potus", "Epipremnum aureum", "Potus", "Potus (Epipremnum aureum)"), (nil, "Ficus", "Ficus", "Ficus"), ("Ficus", "Ficus", "Ficus", "Ficus"), ("Árbol", nil, "Árbol", "Árbol")] as [(String?, String?, String, String)] {
            let plant = try snapshot(photo: photo, source: .aiProposal(resultID: UUID(), selection: .primary, commonName: common, scientificName: scientific)).plant()
            XCTAssertEqual(plant.name, name); XCTAssertEqual(plant.confirmedSpecies, species)
        }
    }

    func testRejectMismatchedIdentityDatePhotoIDAndInvalidFields() throws {
        let photo = IdentificationPhoto(id: UUID(), jpeg: Data([1]), width: 1, height: 1)
        let good = snapshot(photo: photo)
        for bad in [snapshot(photo: photo, source: .manual(name: " \n")), snapshot(photo: photo, source: .manual(name: String(repeating: "x", count: 2001))), snapshot(photo: photo, id: photo.id), ConfirmedPlantSnapshot(id: UUID(), createdAt: Date(timeIntervalSince1970: .infinity), photo: photo, identity: good.identity, careSheet: good.careSheet), ConfirmedPlantSnapshot(id: UUID(), createdAt: good.createdAt, photo: photo, identity: ConfirmedDraftIdentity(photoID: UUID(), source: good.identity.source), careSheet: good.careSheet)] {
            XCTAssertThrowsError(try bad.plant())
        }
        for index in 0..<6 {
            for invalid in [" \n", String(repeating: "x", count: 1001)] {
                var values = good.careSheet.requiredFields; values[index] = invalid
                let sheet = CareSheet(light: values[0], watering: values[1], humidity: values[2], temperature: values[3], substrate: values[4], fertilizer: values[5])
                XCTAssertThrowsError(try ConfirmedPlantSnapshot(id: UUID(), createdAt: good.createdAt, photo: photo, identity: good.identity, careSheet: sheet).plant())
            }
        }
    }

    func testRealPreparedBytesTwoCopiesRelaunchAndDuplicateReconciliation() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalPlantRepository(root: root)
        let photo = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1))
        let useCase = SaveConfirmedPlant(repository: repository, photoValidator: LocalPreparedPlantPhotoValidator())
        let a = snapshot(photo: photo)
        let otherPhoto = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
        let originalB = snapshot(photo: otherPhoto)
        let b = ConfirmedPlantSnapshot(id: originalB.id, createdAt: originalB.createdAt, photo: otherPhoto, identity: originalB.identity,
            careSheet: CareSheet(light: "Otra luz", watering: "Otro riego", humidity: "Otra humedad", temperature: "Otra temperatura", substrate: "Otro sustrato", fertilizer: "Otro abonado"))
        let first = try await useCase.execute(a, willCommit: {})
        let second = try await useCase.execute(b, willCommit: {})
        XCTAssertNotEqual(first.id, second.id)
        let reconciled = try await useCase.execute(a, willCommit: {})
        XCTAssertEqual(reconciled, first)
        let reopened = LocalPlantRepository(root: root)
        let plants = try await reopened.loadPlants(); XCTAssertEqual(Set(plants.map(\.id)), Set([first.id, second.id]))
        for (id, expected) in [(first.id, photo.jpeg), (second.id, otherPhoto.jpeg)] {
            let bytes = try await reopened.loadInitialPhoto(for: id); XCTAssertEqual(bytes, expected)
        }
        XCTAssertNotEqual(first.careSheet, second.careSheet); XCTAssertNotEqual(photo.jpeg, otherPhoto.jpeg)
        let conflict = snapshot(photo: photo, source: .manual(name: "Otra"), id: first.id)
        do { _ = try await useCase.execute(conflict, willCommit: {}); XCTFail("Overwrote UUID") }
        catch { XCTAssertEqual(error as? PlantStorageError, .duplicateID) }
        let unchanged = try await reopened.loadPlants(); XCTAssertEqual(unchanged, plants)
    }

    func testPrecommitCancellationAndRealRollbackThenSameSnapshotRetry() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let fault = CreationCommitFault()
        let repository = LocalPlantRepository(root: root, beforeCommit: { try fault.check() })
        let photo = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1))
        let snapshot = snapshot(photo: photo)
        let useCase = SaveConfirmedPlant(repository: repository, photoValidator: LocalPreparedPlantPhotoValidator())
        do { _ = try await useCase.execute(snapshot, willCommit: { throw CancellationError() }); XCTFail("Cancelled commit") }
        catch { XCTAssertTrue(error is CancellationError) }
        do { _ = try await useCase.execute(snapshot, willCommit: {}); XCTFail("Expected rollback") }
        catch { XCTAssertEqual(error as? PlantStorageError, .storage) }
        let empty = try await repository.loadPlants(); XCTAssertTrue(empty.isEmpty)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("Photos").path).isEmpty)
        fault.disable()
        let saved = try await useCase.execute(snapshot, willCommit: {})
        XCTAssertEqual(saved.id, snapshot.id); XCTAssertEqual(saved.createdAt, snapshot.createdAt)
    }
}
