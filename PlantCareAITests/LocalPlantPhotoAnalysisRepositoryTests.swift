import XCTest
import SwiftData
@testable import PlantCareAI

final class LocalPlantPhotoAnalysisRepositoryTests: XCTestCase {
    private var root: URL!
    override func setUp() { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    private func seed() async throws {
        let repository = LocalPlantRepository(root: root)
        for index in 1...2 { try await repository.savePlant(StorageTestFixture.plant(index), initialPhoto: StorageTestFixture.photo(1)) }
    }
    private func photo() async throws -> (PlantPhoto, Data) {
        let prepared = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(1))
        return (.init(id: UUID(), plantID: StorageTestFixture.plant(1).id, occurredAt: Date(timeIntervalSince1970: 86_400),
            createdAt: Date(timeIntervalSince1970: 200_000), timeZoneIdentifier: "Africa/Abidjan", width: prepared.width, height: prepared.height), prepared.jpeg)
    }
    private func snapshot(_ photo: PlantPhoto) -> PlantPhotoAnalysisAcceptance {
        KeepPlantPhotoAnalysisTests.snapshot(source: .init(id: .additional(photo.id), date: photo.occurredAt, createdAt: photo.createdAt))
    }

    private struct DurableSnapshot: Equatable {
        let plants: [Plant]
        let care: [[CareEvent]]
        let photos: [[PlantPhoto]]
        let analyses: [[SavedPlantPhotoAnalysis]]
        let jpeg: [Data]
    }

    private func durableSnapshot(_ repository: LocalPlantRepository) async throws -> DurableSnapshot {
        let plants = try await repository.loadPlants()
        var care: [[CareEvent]] = [], photos: [[PlantPhoto]] = [], analyses: [[SavedPlantPhotoAnalysis]] = [], jpeg: [Data] = []
        for plant in plants {
            care.append(try await repository.loadCareEvents(for: plant.id))
            let ownPhotos = try await repository.loadPhotos(for: plant.id); photos.append(ownPhotos)
            analyses.append(try await repository.loadSavedAnalyses(for: plant.id))
            jpeg.append(try await repository.loadInitialPhoto(for: plant.id))
            for photo in ownPhotos { jpeg.append(try await repository.loadPhoto(id: photo.id, for: plant.id)) }
        }
        return .init(plants: plants, care: care, photos: photos, analyses: analyses, jpeg: jpeg)
    }

    @MainActor
    func testDiscardInitialAndAdditionalPreservesRealDiskTimelineDefinitivesCareAndJPEGAfterReopen() async throws {
        try await seed(); let (photo, jpeg) = try await photo()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        _ = try await repository!.savePhoto(photo, jpeg: jpeg)
        let previous = KeepPlantPhotoAnalysisTests.snapshot(plant: StorageTestFixture.plant(2))
        _ = try await repository!.saveAccepted(previous)
        for event in legacyEvents(3) { _ = try await repository!.saveCareEvent(event) }
        let before = try await durableSnapshot(repository!)
        let scope = ExternalAIConsent(recipient: "discard-test", noticeVersion: 5), consent = ConsentDouble()
        await consent.configure(value: scope)
        let provider = AnalysisProviderSpy(); var callbacks = 0
        for identity in [PlantPhotoIdentity.initial(photo.plantID), .additional(photo.id)] {
            let use = AnalyzePlantPhoto(detail: .init(repository: repository!), care: repository!, photos: repository!,
                initial: .init(repository: repository!), repository: provider, gate: .init(), acceptedReader: repository!, validateJPEG: { _ in })
            let vm = PlantPhotoAnalysisViewModel(plantID: photo.plantID, identity: identity, analyze: use,
                authorize: .init(repository: consent, scope: scope), destination: nil, keep: KeepPlantPhotoAnalysis(repository: repository!),
                onSaved: { _ in callbacks += 1 }, configurationIsCurrent: { true })
            vm.start()
            for _ in 0..<500 { if vm.state == .result { break }; try await Task.sleep(for: .milliseconds(10)) }
            XCTAssertEqual(vm.state, .result); XCTAssertTrue(vm.discard()); vm.save(); XCTAssertFalse(vm.discard())
            let after = try await durableSnapshot(repository!); XCTAssertEqual(after, before)
            let timeline = try await LoadPlantTimeline(detail: .init(repository: repository!), care: repository!, photos: repository!, analyses: repository!).snapshot(for: photo.plantID)
            XCTAssertEqual(timeline?.entries.count, 7); XCTAssertTrue(timeline?.analyses.isEmpty == true)
        }
        XCTAssertEqual(callbacks, 0); let calls = await provider.calls; XCTAssertEqual(calls.count, 2)
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let afterReopen = try await durableSnapshot(reopened); XCTAssertEqual(afterReopen, before)
        let records = try await reopened.loadSavedAnalyses(for: previous.record.plantID); XCTAssertEqual(records, [previous.record])
        let blocked = AnalyzePlantPhoto(detail: .init(repository: reopened), care: reopened, photos: reopened,
            initial: .init(repository: reopened), repository: provider, gate: .init(), acceptedReader: reopened, validateJPEG: { _ in })
        do { _ = try await blocked.prepare(plantID: previous.record.plantID, identity: previous.record.identity, queriedAt: Date(), timeZone: .current); XCTFail("definitive remains blocked") }
        catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .alreadyAnalyzed) }
    }

    func testDurableInitialAdditionalIdentityIsolationExactJPEGNoCareAndSingleTimelineHito() async throws {
        try await seed()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let (photo, jpeg) = try await photo()
        _ = try await repository!.savePhoto(photo, jpeg: jpeg)
        let initial = KeepPlantPhotoAnalysisTests.snapshot(), additional = snapshot(photo)
        for value in [initial, additional] { let saved = try await repository!.saveAccepted(value); XCTAssertEqual(saved, value.record) }
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        let records = try await reopened.loadSavedAnalyses(for: initial.record.plantID)
        XCTAssertEqual(Set(records.map(\.id)), Set([initial.record.id, additional.record.id]))
        XCTAssertTrue(records.contains(initial.record)); XCTAssertTrue(records.contains(additional.record))
        let other = try await reopened.loadSavedAnalyses(for: StorageTestFixture.plant(2).id); XCTAssertTrue(other.isEmpty)
        let actualJPEG = try await reopened.loadPhoto(id: photo.id, for: photo.plantID); XCTAssertEqual(actualJPEG, jpeg)
        for index in 1...2 {
            let bytes = try await reopened.loadInitialPhoto(for: StorageTestFixture.plant(index).id); XCTAssertEqual(bytes, StorageTestFixture.photo(1))
            let care = try await reopened.loadCareEvents(for: StorageTestFixture.plant(index).id); XCTAssertTrue(care.isEmpty)
        }
        let timeline = LoadPlantTimeline(detail: .init(repository: reopened), care: reopened, photos: reopened, analyses: reopened)
        let projection = try await timeline.snapshot(for: photo.plantID)
        XCTAssertEqual(projection?.entries.count, 2); XCTAssertEqual(projection?.analyses.count, 2)
        let plants = try await reopened.loadPlants(); XCTAssertEqual(plants, (1...2).map(StorageTestFixture.plant))
    }

    func testIdempotencyConcurrentAcceptanceConflictAndLiteralMismatchNeverOverwrite() async throws {
        try await seed(); let repository = LocalPlantRepository(root: root), value = KeepPlantPhotoAnalysisTests.snapshot()
        async let a = repository.saveAccepted(value)
        async let b = repository.saveAccepted(value)
        let results = try await [a, b]; XCTAssertEqual(results, [value.record, value.record])
        for conflict in [KeepPlantPhotoAnalysisTests.snapshot(), KeepPlantPhotoAnalysisTests.snapshot(id: value.record.id,
            content: .init(outcome: .analysis, observations: ["different"], possibleCauses: [], checks: ["check"]))] {
            do { _ = try await repository.saveAccepted(conflict); XCTFail("overwrite") }
            catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .conflict) }
        }
        let records = try await repository.loadSavedAnalyses(for: value.record.plantID); XCTAssertEqual(records, [value.record])
    }

    func testRollbackRetrySnapshotAndMissingOrChangedOriginNotRecreated() async throws {
        try await seed(); let value = KeepPlantPhotoAnalysisTests.snapshot()
        var fault: LocalPlantRepository? = LocalPlantRepository(root: root, beforeAnalysisCommit: { throw KeepPlantPhotoAnalysisError.storage })
        do { _ = try await fault!.saveAccepted(value); XCTFail() } catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .storage) }
        let empty = try await fault!.loadSavedAnalyses(for: value.record.plantID); XCTAssertTrue(empty.isEmpty); fault = nil
        let repository = LocalPlantRepository(root: root)
        let reopenedEmpty = try await repository.loadSavedAnalyses(for: value.record.plantID); XCTAssertTrue(reopenedEmpty.isEmpty)
        let saved = try await repository.saveAccepted(value); XCTAssertEqual(saved, value.record)
        let stale = KeepPlantPhotoAnalysisTests.snapshot(plant: StorageTestFixture.plant(2),
            source: .init(id: .initial(StorageTestFixture.plant(2).id), date: Date(timeIntervalSince1970: 1), createdAt: Date(timeIntervalSince1970: 1)))
        do { _ = try await repository.saveAccepted(stale); XCTFail() } catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .conflict) }
        let absent = KeepPlantPhotoAnalysisTests.snapshot(source: .init(id: .additional(UUID()), date: Date(), createdAt: Date()))
        do { _ = try await repository.saveAccepted(absent); XCTFail() } catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .notFound) }
    }

    func testDeletionRollbackTogetherAndPostcommitCleanupFailureNeverResurrectsText() async throws {
        try await seed(); let (photo, jpeg) = try await photo(), value = snapshot(photo)
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        _ = try await repository!.savePhoto(photo, jpeg: jpeg); _ = try await repository!.saveAccepted(value); repository = nil
        var fault: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCommit: { throw PlantPhotoError.storage })
        do { _ = try await fault!.deletePhoto(photo); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoError, .storage) }
        let records = try await fault!.loadSavedAnalyses(for: photo.plantID); XCTAssertEqual(records, [value.record])
        let photos = try await fault!.loadPhotos(for: photo.plantID); XCTAssertEqual(photos, [photo]); fault = nil
        var cleanup: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCleanup: { throw PlantPhotoError.storage })
        _ = try await cleanup!.deletePhoto(photo)
        let empty = try await cleanup!.loadAccepted(for: photo.plantID); XCTAssertTrue(empty.isEmpty)
        let file = root.appendingPathComponent("AdditionalPhotos/\(photo.id).jpg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path)); cleanup = nil
        let reopened = LocalPlantRepository(root: root); _ = try await reopened.loadPlants()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    private func oldStore(_ version: Int, additionalJPEG: Data) throws {
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Photos"), withIntermediateDirectories: true)
        let config = ModelConfiguration(url: root.appendingPathComponent("Plants.store"))
        let container: ModelContainer
        switch version {
        case 1: container = try ModelContainer(for: PersistedPlant.self, configurations: config)
        case 2: container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, configurations: config)
        default: container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self, configurations: config)
        }
        let context = ModelContext(container); context.autosaveEnabled = false
        context.insert(PersistedPlant(StorageTestFixture.plant(1)))
        try StorageTestFixture.photo(1).write(to: root.appendingPathComponent("Photos/\(StorageTestFixture.plant(1).id).jpg"))
        if version >= 2 {
            for event in legacyEvents(version) { context.insert(PersistedCareEvent(event)) }
        }
        if version >= 3 {
            let photo = legacyPhoto()
            context.insert(PersistedPlantPhoto(photo))
            let directory = root.appendingPathComponent("AdditionalPhotos")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try additionalJPEG.write(to: directory.appendingPathComponent("\(photo.id).jpg"))
        }
        try context.save()
    }

    private func legacyPhoto() -> PlantPhoto {
        .init(id: UUID(uuidString: "12345678-0000-0000-0000-000000000001")!, plantID: StorageTestFixture.plant(1).id,
            occurredAt: Date(timeIntervalSince1970: 86_400), createdAt: Date(timeIntervalSince1970: 200_000),
            timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480)
    }

    private func legacyEvents(_ version: Int) -> [CareEvent] {
        guard version >= 2 else { return [] }
        return CareEvent.Kind.allCases.enumerated().map { index, kind in
            .init(id: UUID(uuidString: String(format: "12345678-0000-0000-0000-%012d", index + 2))!,
                plantID: StorageTestFixture.plant(1).id, kind: kind, occurredAt: Date(timeIntervalSince1970: 86_400),
                note: "old V\(version) e\u{301}\n🌿 \(index)", createdAt: Date(timeIntervalSince1970: 200_000),
                timeZoneIdentifier: "Africa/Abidjan")
        }
    }

    func testRealV1V2V3AdditiveUpgradeToV4NoReset() async throws {
        for version in 1...3 {
            let (_, additionalJPEG) = try await photo()
            try oldStore(version, additionalJPEG: additionalJPEG)
            var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
            let value = KeepPlantPhotoAnalysisTests.snapshot()
            _ = try await repository!.saveAccepted(value); repository = nil
            let reopened = LocalPlantRepository(root: root)
            let records = try await reopened.loadSavedAnalyses(for: value.record.plantID); XCTAssertEqual(records, [value.record])
            let bytes = try await reopened.loadInitialPhoto(for: value.record.plantID); XCTAssertEqual(bytes, StorageTestFixture.photo(1))
            let care = try await reopened.loadCareEvents(for: value.record.plantID)
            XCTAssertEqual(Set(care.map(\.id)), Set(legacyEvents(version).map(\.id)))
            XCTAssertTrue(legacyEvents(version).allSatisfy { care.contains($0) })
            let photos = try await reopened.loadPhotos(for: value.record.plantID)
            XCTAssertEqual(photos, version == 3 ? [legacyPhoto()] : [])
            if version == 3 {
                let additionalBytes = try await reopened.loadPhoto(id: legacyPhoto().id, for: value.record.plantID)
                XCTAssertEqual(additionalBytes, additionalJPEG)
            }
            try FileManager.default.removeItem(at: root)
        }
    }

    private func corruptStore(_ mode: Int) throws {
        let config = ModelConfiguration(url: root.appendingPathComponent("Plants.store"))
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self, PersistedPlantPhotoAnalysis.self, configurations: config)
        let context = ModelContext(container); context.autosaveEnabled = false
        let value = KeepPlantPhotoAnalysisTests.snapshot()
        let record = try PersistedPlantPhotoAnalysis(value)
        switch mode {
        case 0: record.identityKind = "unknown"
        case 1: record.photoID = UUID()
        case 2: record.contentData = Data("{}".utf8)
        case 3: context.insert(try PersistedPlantPhotoAnalysis(KeepPlantPhotoAnalysisTests.snapshot()))
        default: record.photoDate = Date(timeIntervalSince1970: 1)
        }
        context.insert(record); try context.save()
    }

    func testCorruptRawContentDuplicateAndBrokenLinksFailBeforeOrphanCleanup() async throws {
        for mode in 0...4 {
            try await seed(); try corruptStore(mode)
            let orphan = root.appendingPathComponent("Photos/orphan.jpg"); try Data([1, 2]).write(to: orphan)
            do { _ = try await LocalPlantRepository(root: root).loadSavedAnalyses(for: StorageTestFixture.plant(1).id); XCTFail("corrupt empty") }
            catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .readFailure) }
            XCTAssertEqual(try Data(contentsOf: orphan), Data([1, 2]))
            try FileManager.default.removeItem(at: root)
        }
    }

    func testRealReaderBlocksPrepareAndExecuteAndTextContextUsesSourceNotAcceptanceNoHistoricalJPEG() async throws {
        try await seed(); let (photo, jpeg) = try await photo()
        let repository = LocalPlantRepository(root: root), provider = AnalysisProviderSpy()
        _ = try await repository.savePhoto(photo, jpeg: jpeg)
        let use = AnalyzePlantPhoto(detail: .init(repository: repository), care: repository, photos: repository,
            initial: .init(repository: repository), repository: provider, gate: .init(), acceptedReader: repository, validateJPEG: { _ in })
        let prepared = try await use.prepare(plantID: photo.plantID, identity: .additional(photo.id), queriedAt: Date(), timeZone: TimeZone(secondsFromGMT: 0)!)
        _ = try await repository.saveAccepted(snapshot(photo))
        do { _ = try await use.execute(prepared); XCTFail() } catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .alreadyAnalyzed) }
        do { _ = try await use.prepare(plantID: photo.plantID, identity: .additional(photo.id), queriedAt: Date(), timeZone: TimeZone(secondsFromGMT: 0)!); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoAnalysisError, .alreadyAnalyzed) }
        let calls = await provider.calls; XCTAssertTrue(calls.isEmpty)
        try FileManager.default.removeItem(at: root.appendingPathComponent("AdditionalPhotos/\(photo.id).jpg"))
        let accepted = try await repository.loadAccepted(for: photo.plantID); XCTAssertEqual(accepted.count, 1)
        XCTAssertEqual(accepted.first?.photoDate, photo.occurredAt)
        let projection = try await LoadPlantTimeline(detail: .init(repository: repository), care: repository, photos: repository, analyses: repository).snapshot(for: photo.plantID)
        XCTAssertEqual(projection?.analyses.count, 1)
    }

    func testRealContextIncludesEarlierSourceDespiteLaterAcceptanceAndExcludesSameDayOtherPlant() async throws {
        try await seed()
        let repository = LocalPlantRepository(root: root)
        let initial = KeepPlantPhotoAnalysisTests.snapshot()
        _ = try await repository.saveAccepted(initial)
        _ = try await repository.saveAccepted(KeepPlantPhotoAnalysisTests.snapshot(plant: StorageTestFixture.plant(2)))
        let (photo, jpeg) = try await photo()
        _ = try await repository.savePhoto(photo, jpeg: jpeg)
        // Source day1 is after initial day0, but acceptedAt day34 is after both.
        // Delete historical JPEG to ensure preparation cannot read it accidentally.
        try FileManager.default.removeItem(at: root.appendingPathComponent("Photos/\(photo.plantID).jpg"))
        let use = AnalyzePlantPhoto(detail: .init(repository: repository), care: repository, photos: repository,
            initial: .init(repository: repository), repository: AnalysisProviderSpy(), gate: .init(), acceptedReader: repository, validateJPEG: { _ in })
        let prepared = try await use.prepare(plantID: photo.plantID, identity: .additional(photo.id), queriedAt: Date(), timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(prepared.context.previousAcceptedInterpretations.count, 1)
        XCTAssertEqual(prepared.context.previousAcceptedInterpretations.first?.interpretation, initial.record.content)
        XCTAssertEqual(prepared.context.previousAcceptedInterpretations.first?.photoDate, "1970-01-01")
        XCTAssertLessThanOrEqual(try prepared.context.encoded().count, 16 * 1024)
        let sameDay = PlantPhotoDescriptor(id: .additional(UUID()), date: initial.record.photoDate, createdAt: Date())
        let previous = try await repository.loadAccepted(for: photo.plantID)
        let context = try BuildPlantAnalysisContext().execute(plant: StorageTestFixture.plant(1), photo: sameDay,
            care: [], accepted: previous, queriedAt: Date(), timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertTrue(context.previousAcceptedInterpretations.isEmpty)
    }
}
