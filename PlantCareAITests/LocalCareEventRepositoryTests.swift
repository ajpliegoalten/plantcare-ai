import XCTest
import SwiftData
@testable import PlantCareAI

final class LocalCareEventRepositoryTests: XCTestCase {
    func testLastWateringRealReopenMaxAndReadOnlyExactPlantPhotoAndPayload() async throws {
        try seedV1()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let newest = try event()
        let older = CareEvent(id: UUID(), plantID: newest.plantID, kind: .watering,
                             occurredAt: newest.occurredAt.addingTimeInterval(-86400), note: "Retroactivo", createdAt: newest.createdAt.addingTimeInterval(50), timeZoneIdentifier: newest.timeZoneIdentifier)
        let otherKind = CareEvent(id: UUID(), plantID: newest.plantID, kind: .other,
                                 occurredAt: newest.occurredAt.addingTimeInterval(86400), note: nil, createdAt: newest.createdAt, timeZoneIdentifier: newest.timeZoneIdentifier)
        for event in [newest, otherKind, older] { _ = try await repository!.saveCareEvent(event) }
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let first = try await LoadLastWatering(repository: reopened).execute(for: newest.plantID)
        let second = try await LoadLastWatering(repository: reopened).execute(for: StorageTestFixture.plant(2).id)
        XCTAssertEqual(first, newest.occurredAt); XCTAssertNil(second)
        let actual = try await reopened.loadCareEvents(for: newest.plantID)
        XCTAssertEqual(actual, [otherKind, newest, older])
        try await assertPlants(reopened)
    }
    var root: URL!
    override func setUpWithError() throws { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    func event(id: UUID = UUID(), plantID: UUID = StorageTestFixture.plant(1).id, zone: String = "Europe/Madrid", note: String? = "Agua\n🌿") throws -> CareEvent {
        CareEvent(id: id, plantID: plantID, kind: .watering,
                  occurredAt: try RegisterCareEvent.startOfDay(year: 2020, month: 1, day: 2, zone: try RegisterCareEvent.zone(zone)),
                  note: note, createdAt: Date(timeIntervalSince1970: 1_700_000_000), timeZoneIdentifier: zone)
    }

    func seedV1() throws {
        // Real previous schema on disk: deliberately ONLY PersistedPlant.
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Photos"), withIntermediateDirectories: true)
        let container = try ModelContainer(for: PersistedPlant.self, configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        for index in 1...2 {
            context.insert(PersistedPlant(StorageTestFixture.plant(index)))
            try StorageTestFixture.photo(index).write(to: root.appendingPathComponent("Photos/\(StorageTestFixture.plant(index).id).jpg"))
        }
        try context.save()
    } // container/context released BEFORE V2 opens.

    func assertPlants(_ repository: LocalPlantRepository) async throws {
        let plants = try await repository.loadPlants()
        XCTAssertEqual(plants, (1...2).map(StorageTestFixture.plant))
        for index in 1...2 {
            let bytes = try await repository.loadInitialPhoto(for: StorageTestFixture.plant(index).id)
            XCTAssertEqual(bytes, StorageTestFixture.photo(index))
        }
    }

    func testRealDiskV1UpgradeThenSevenFieldRoundtripIsolationAndSecondIntention() async throws {
        try seedV1()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        try await assertPlants(repository!)
        for index in 1...2 { let events = try await repository!.loadCareEvents(for: StorageTestFixture.plant(index).id); XCTAssertEqual(events, []) }
        let first = try event(), second = try event()
        let saved = try await repository!.saveCareEvent(first); XCTAssertEqual(saved, first)
        _ = try await repository!.saveCareEvent(second)
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let events = try await reopened.loadCareEvents(for: first.plantID)
        XCTAssertEqual(Set(events.map(\.id)), Set([first.id, second.id]))
        XCTAssertTrue(events.contains(first)); XCTAssertTrue(events.contains(second))
        let other = try await reopened.loadCareEvents(for: StorageTestFixture.plant(2).id); XCTAssertEqual(other, [])
        try await assertPlants(reopened)
    }

    func testRollbackRetryDuplicateReconciliationBeforeClockAndZoneOnlyConflict() async throws {
        try seedV1()
        let fault = WateringCommitFault()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeCommit: { try fault.check() })
        let original = try event()
        do { _ = try await repository!.saveCareEvent(original); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .storage) }
        let empty = try await repository!.loadCareEvents(for: original.plantID); XCTAssertEqual(empty, [])
        repository = nil
        repository = LocalPlantRepository(root: root, beforeCommit: { try fault.check() })
        let diskEmpty = try await repository!.loadCareEvents(for: original.plantID); XCTAssertEqual(diskEmpty, [])
        fault.disable()
        let result = try await repository!.saveCareEvent(original); XCTAssertEqual(result, original)
        repository = nil
        let backward = LocalPlantRepository(root: root, now: { original.occurredAt.addingTimeInterval(-1) })
        let duplicate = try await RegisterCareEvent(repository: backward).execute(event: original, now: original.occurredAt.addingTimeInterval(-1))
        XCTAssertEqual(duplicate, original)
        let changedZone = CareEvent(id: original.id, plantID: original.plantID, kind: .watering, occurredAt: original.occurredAt,
            note: original.note, createdAt: original.createdAt, timeZoneIdentifier: "Europe/Paris")
        do { _ = try await backward.saveCareEvent(changedZone); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .conflict) }
        do { _ = try await backward.saveCareEvent(try event()); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .validation) }
        let events = try await backward.loadCareEvents(for: original.plantID); XCTAssertEqual(events, [original])
        try await assertPlants(backward)
    }

    func testMissingPlantUnreadableStoreAndCorruptZoneAreErrorsNotEmpty() async throws {
        let repository = LocalPlantRepository(root: root)
        do { _ = try await repository.saveCareEvent(try event()); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .plantNotFound) }
        do { _ = try await repository.loadCareEvents(for: UUID()); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .plantNotFound) }
        try FileManager.default.removeItem(at: root)
        try seedV1()
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        let corrupt = PersistedCareEvent(try event()); corrupt.timeZoneIdentifier = "Invalid/Unknown"
        context.insert(corrupt); try context.save()
        let fresh = LocalPlantRepository(root: root)
        do { _ = try await fresh.loadCareEvents(for: corrupt.plantID); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .storage) }
        let badRoot = root.appendingPathComponent("bad")
        try FileManager.default.createDirectory(at: badRoot, withIntermediateDirectories: true)
        try Data("invalid".utf8).write(to: badRoot.appendingPathComponent("Plants.store"))
        do { _ = try await LocalPlantRepository(root: badRoot).loadCareEvents(for: UUID()); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .storage) }
    }

    func testDirectNormalizationAndStableDescendingOrdering() async throws {
        try seedV1()
        let repository = LocalPlantRepository(root: root)
        let first = try event(note: " \n ")
        let normalized = try await repository.saveCareEvent(first)
        XCTAssertNil(normalized.note)
        let second = CareEvent(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, plantID: first.plantID,
            kind: .watering, occurredAt: first.occurredAt, note: "Dos", createdAt: first.createdAt.addingTimeInterval(1), timeZoneIdentifier: first.timeZoneIdentifier)
        let third = CareEvent(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, plantID: first.plantID,
            kind: .watering, occurredAt: second.occurredAt, note: "Tres", createdAt: second.createdAt, timeZoneIdentifier: second.timeZoneIdentifier)
        _ = try await repository.saveCareEvent(third); _ = try await repository.saveCareEvent(second)
        let events = try await repository.loadCareEvents(for: first.plantID)
        XCTAssertEqual(events, [second, third, normalized])
    }

    func testFixtureComparesLiteralMultilinePayloadAndExpectedDayAfterRecreation() async throws {
        try seedV1()
        let fixture = CareEventTestFixture(root: root, mode: "success")
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeCareCommit: { try fixture.beforeCareCommit($0) })
        let note = "Agua\nSegunda línea"
        let occurredAt = try RegisterCareEvent.startOfDay(year: 2020, month: 1, day: 2, zone: try RegisterCareEvent.zone("Europe/Madrid"))
        let event = CareEvent(id: UUID(), plantID: StorageTestFixture.plant(1).id, kind: .watering, occurredAt: occurredAt,
            note: " \n" + note + "\n ", createdAt: occurredAt.addingTimeInterval(86400 + 3600), timeZoneIdentifier: "Europe/Madrid")
        _ = try await repository!.saveCareEvent(event)
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        try await CareEventTestFixture.verify(root: root, repository: reopened, count: 1,
            arguments: ["--care-expected-offset", "-1", "--care-expected-note-base64", Data(note.utf8).base64EncodedString()])
    }

    func testCanonicallyEquivalentButDifferentUnicodePayloadIsConflictWithoutOverwrite() async throws {
        try seedV1()
        let repository = LocalPlantRepository(root: root)
        let original = try event(note: "é")
        _ = try await repository.saveCareEvent(original)
        let changed = CareEvent(id: original.id, plantID: original.plantID, kind: original.kind, occurredAt: original.occurredAt,
            note: "e\u{301}", createdAt: original.createdAt, timeZoneIdentifier: original.timeZoneIdentifier)
        XCTAssertEqual(original.note, changed.note) // Swift String's canonical equivalence is NOT literal payload equality.
        XCTAssertNotEqual(original, changed)
        do { _ = try await repository.saveCareEvent(changed); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .conflict) }
        let events = try await LocalPlantRepository(root: root).loadCareEvents(for: original.plantID)
        XCTAssertEqual(events, [original]); XCTAssertEqual(Array(events[0].note!.utf8), Array("é".utf8))
    }

    private func seedV2Watering(_ original: CareEvent) throws {
        // Same V2 schema as the accepted application, with a literal legacy raw.
        try seedV1()
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container); context.autosaveEnabled = false
        let row = PersistedCareEvent(original); row.kind = "watering"
        context.insert(row); try context.save()
    } // Both context and container released before the new reader opens.

    func testRealV2WateringCompatibilityFiveKindsNilAndNotesOrderingAndIsolation() async throws {
        let original = try event(note: "e\u{301}\n  Agua")
        try seedV2Watering(original)
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let legacy = try await repository!.loadCareEvents(for: original.plantID)
        XCTAssertEqual(legacy, [original]); try await assertPlants(repository!)
        var expected = [original]
        for (index, kind) in CareEvent.Kind.allCases.enumerated() {
            for note in [nil, "🌿 \(kind.rawValue)\n  e\u{301}"] as [String?] {
                let added = CareEvent(id: UUID(), plantID: original.plantID, kind: kind,
                    occurredAt: original.occurredAt.addingTimeInterval(index == 0 ? -86400 : 86400), note: note,
                    createdAt: original.createdAt.addingTimeInterval(Double(index)), timeZoneIdentifier: original.timeZoneIdentifier)
                let result = try await repository!.saveCareEvent(added); XCTAssertEqual(result, added); expected.append(added)
            }
        }
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let actual = try await reopened.loadCareEvents(for: original.plantID)
        expected.sort { lhs, rhs in
            if lhs.occurredAt != rhs.occurredAt { return lhs.occurredAt > rhs.occurredAt }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        XCTAssertEqual(actual, expected); XCTAssertTrue(actual.contains(original))
        let other = try await reopened.loadCareEvents(for: StorageTestFixture.plant(2).id); XCTAssertTrue(other.isEmpty)
        try await assertPlants(reopened)
    }

    func testKindOnlyConflictNeverOverwritesAndUnknownRawFailsBeforeCleanup() async throws {
        let original = try event()
        try seedV2Watering(original)
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let changed = CareEvent(id: original.id, plantID: original.plantID, kind: .fertilizing, occurredAt: original.occurredAt,
            note: original.note, createdAt: original.createdAt, timeZoneIdentifier: original.timeZoneIdentifier)
        do { _ = try await repository!.saveCareEvent(changed); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .conflict) }
        let stillOriginal = try await repository!.loadCareEvents(for: original.plantID); XCTAssertEqual(stillOriginal, [original])
        repository = nil
        try writeUnknownRaw()
        let pending = root.appendingPathComponent("Photos/keep.pending")
        try Data("keep".utf8).write(to: pending)
        let fresh = LocalPlantRepository(root: root)
        do { _ = try await fresh.loadCareEvents(for: original.plantID); XCTFail() } catch { XCTAssertEqual(error as? CareEventError, .storage) }
        XCTAssertEqual(try Data(contentsOf: pending), Data("keep".utf8))
    }

    private func writeUnknownRaw() throws {
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<PersistedCareEvent>())
        rows[0].kind = "unknown-care-kind"; try context.save()
    }
}

private final class WateringCommitFault: @unchecked Sendable {
    private let lock = NSLock()
    private var active = true
    func disable() { lock.lock(); defer { lock.unlock() }; active = false }
    func check() throws { lock.lock(); defer { lock.unlock() }; if active { throw CareEventError.storage } }
}
