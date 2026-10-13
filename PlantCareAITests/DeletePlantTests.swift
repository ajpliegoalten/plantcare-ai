import XCTest
import SwiftData
@testable import PlantCareAI

final class DeletePlantTests: XCTestCase {
    private var root: URL!
    override func setUp() { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) }
    override func tearDown() { try? FileManager.default.removeItem(at: root) }
    private func seed() async throws {
        let repository = LocalPlantRepository(root: root)
        _ = try await DeletePlantFixtureLoad(base: StorageFixtureLoad(root: root, repository: repository, seed: true, corrupt: false),
            repository: repository, root: root, seed: true, verify: "intact").execute()
    }
    private func verify(_ repository: LocalPlantRepository, _ mode: String) async throws {
        _ = try await DeletePlantFixtureLoad(base: LoadPlants(repository: repository), repository: repository,
            root: root, seed: false, verify: mode).execute()
    }
    private func bytes() throws -> [String: Data] {
        var values: [String: Data] = [:]
        for directory in ["Photos", "AdditionalPhotos"] {
            for file in try FileManager.default.contentsOfDirectory(at: root.appendingPathComponent(directory), includingPropertiesForKeys: nil) {
                values[directory + "/" + file.lastPathComponent] = try Data(contentsOf: file)
            }
        }
        return values
    }

    func testCascadeAllFourEntitiesSameSpeciesCrossTypeIDsIdenticalJPEGAndReopenThenLastPlant() async throws {
        try await seed()
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root)
        let removed = try await DeletePlant(repository: repository!).execute(StorageTestFixture.plant(1))
        XCTAssertEqual(removed, StorageTestFixture.plant(1))
        try await verify(repository!, "deleted")
        repository = nil
        let reopened = LocalPlantRepository(root: root)
        try await verify(reopened, "deleted")
        _ = try await reopened.deletePlant(StorageTestFixture.plant(2))
        try await verify(reopened, "empty")
        try await verify(LocalPlantRepository(root: root), "empty")
    }

    func testRollbackAfterEveryMutationRetainsMetadataAndEveryByteInActorAndReopenThenRetry() async throws {
        try await seed(); let before = try bytes()
        let fault = DeletePlantTestFixture(mode: "failOnce")
        var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCommit: { try fault.beforeCommit() })
        do { _ = try await repository!.deletePlant(StorageTestFixture.plant(1)); XCTFail("Expected rollback") }
        catch { XCTAssertEqual(error as? PlantDeletionError, .storage) }
        try await verify(repository!, "intact"); XCTAssertEqual(try bytes(), before)
        try await verify(LocalPlantRepository(root: root), "intact")
        _ = try await repository!.deletePlant(StorageTestFixture.plant(1))
        try await verify(repository!, "deleted"); repository = nil
        try await verify(LocalPlantRepository(root: root), "deleted")
    }

    func testSnapshotChangedAbsenceAndDoubleDeleteDoNotDispatchCleanupOrClaimSuccess() async throws {
        try await seed(); let before = try bytes()
        let repository = LocalPlantRepository(root: root)
        let expected = StorageTestFixture.plant(1)
        let changed = try await repository.updatePlant(id: expected.id, name: "Otro nombre", location: nil)
        do { _ = try await repository.deletePlant(expected); XCTFail() }
        catch { XCTAssertEqual(error as? PlantDeletionError, .conflict) }
        XCTAssertEqual(try bytes(), before)
        _ = try await repository.deletePlant(changed)
        let after = try bytes()
        do { _ = try await repository.deletePlant(changed); XCTFail() }
        catch { XCTAssertEqual(error as? PlantDeletionError, .notFound) }
        XCTAssertEqual(try bytes(), after)
    }

    func testCurrentChildrenAddedAfterSnapshotAreIncludedAndPostDeleteWritersRejectAbsentOrigin() async throws {
        try await seed(); let repository = LocalPlantRepository(root: root), plant = StorageTestFixture.plant(1)
        let event = CareEvent(id: UUID(), plantID: plant.id, kind: .other, occurredAt: Date(timeIntervalSince1970: 86400),
            note: "Hijo posterior", createdAt: plant.createdAt, timeZoneIdentifier: "Africa/Abidjan")
        _ = try await repository.saveCareEvent(event)
        _ = try await repository.deletePlant(plant)
        try await verify(repository, "deleted")
        do { _ = try await repository.saveCareEvent(event); XCTFail() }
        catch { XCTAssertEqual(error as? CareEventError, .plantNotFound) }
        let photo = DeletePlantFixtureLoad.photos(plant, index: 1)[0]
        let jpeg = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2)).jpeg
        do { _ = try await repository.savePhoto(photo, jpeg: jpeg); XCTFail() }
        catch { XCTAssertEqual(error as? PlantPhotoError, .plantNotFound) }
        do { _ = try await repository.saveAccepted(DeletePlantFixtureLoad.analyses(plant, index: 1)[0]); XCTFail() }
        catch { XCTAssertEqual(error as? KeepPlantPhotoAnalysisError, .notFound) }
        do { _ = try await repository.updatePlant(id: plant.id, name: "Resucitar", location: nil); XCTFail() }
        catch { XCTAssertEqual(error as? PlantStorageError, .notFound) }
    }

    func testMissingAndCorruptJPEGDoNotBlockMetadataDeletion() async throws {
        for missing in [true, false] {
            root = root.appendingPathComponent(UUID().uuidString); try await seed()
            let plant = StorageTestFixture.plant(1)
            let files = [root.appendingPathComponent("Photos/\(plant.id).jpg")] + DeletePlantFixtureLoad.photos(plant, index: 1).map { root.appendingPathComponent("AdditionalPhotos/\($0.id).jpg") }
            for file in files {
                if missing { try FileManager.default.removeItem(at: file) }
                else { try Data("not a JPEG".utf8).write(to: file) }
            }
            let repository = LocalPlantRepository(root: root)
            _ = try await repository.deletePlant(plant); try await verify(repository, "deleted")
        }
    }

    func testCleanupOneFailureStillAttemptsRemainingFilesAndReopenRecoversBothDirectories() async throws {
        for mode in ["first", "all"] {
            root = root.appendingPathComponent(UUID().uuidString); try await seed()
            let fault = CleanupPlantFault(all: mode == "all")
            var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCleanup: { try fault.run() })
            _ = try await repository!.deletePlant(StorageTestFixture.plant(1))
            XCTAssertEqual(fault.count, 3)
            XCTAssertEqual(try bytes().count, mode == "all" ? 6 : 4)
            repository = nil
            try await verify(LocalPlantRepository(root: root), "deleted")
        }
    }

    func testRecoveryFailsClosedForEachCorruptEntityBeforeEitherDirectoryCleanup() async throws {
        for kind in 0..<4 {
            root = root.appendingPathComponent(UUID().uuidString); try await seed()
            var repository: LocalPlantRepository? = LocalPlantRepository(root: root, beforeDeletionCleanup: { throw PlantDeletionError.storage })
            _ = try await repository!.deletePlant(StorageTestFixture.plant(1)); repository = nil
            let before = try bytes()
            try corrupt(kind)
            do { _ = try await LocalPlantRepository(root: root).loadPlants(); XCTFail() }
            catch { XCTAssertEqual(error as? PlantStorageError, .storage) }
            XCTAssertEqual(try bytes(), before)
        }
    }

    func testUnreadableStoreNeverMutatesJPEG() async throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("broken store".utf8).write(to: root.appendingPathComponent("Plants.store"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Photos"), withIntermediateDirectories: true)
        let file = root.appendingPathComponent("Photos/\(StorageTestFixture.plant(1).id).jpg")
        try Data("sentinel".utf8).write(to: file)
        do { _ = try await LocalPlantRepository(root: root).deletePlant(StorageTestFixture.plant(1)); XCTFail() }
        catch { XCTAssertEqual(error as? PlantDeletionError, .readFailure) }
        XCTAssertEqual(try Data(contentsOf: file), Data("sentinel".utf8))
    }

    func testSingletonWithoutChildrenAndUseCasePassesSnapshotUnchanged() async throws {
        let repository = LocalPlantRepository(root: root), plant = StorageTestFixture.plant(1)
        try await repository.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let result = try await DeletePlant(repository: repository).execute(plant)
        XCTAssertEqual(result, plant)
        let remaining = try await repository.loadPlants(); XCTAssertTrue(remaining.isEmpty)
        XCTAssertTrue(try bytes().isEmpty)
        let reopened = try await LocalPlantRepository(root: root).loadPlants(); XCTAssertTrue(reopened.isEmpty)
    }

    func testForeignChildrenWhoseUUIDMatchesDeletedPlantAndOwnPhotoMatchingOtherPlantStayIsolated() async throws {
        try await seed(); let repository = LocalPlantRepository(root: root)
        let a = StorageTestFixture.plant(1), b = StorageTestFixture.plant(2)
        let foreignEvent = CareEvent(id: a.id, plantID: b.id, kind: .other, occurredAt: Date(timeIntervalSince1970: 86400),
            note: "Coincide UUID con planta A, pertenece B", createdAt: Date(timeIntervalSince1970: 300000), timeZoneIdentifier: "Africa/Abidjan")
        _ = try await repository.saveCareEvent(foreignEvent)
        let jpeg = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2)).jpeg
        for (id, owner) in [(a.id, b.id), (b.id, a.id)] {
            _ = try await repository.savePhoto(.init(id: id, plantID: owner, occurredAt: Date(timeIntervalSince1970: 86400),
                createdAt: Date(timeIntervalSince1970: 300000), timeZoneIdentifier: "Africa/Abidjan", width: 640, height: 480), jpeg: jpeg)
        }
        let eventsBefore = try await repository.loadCareEvents(for: b.id), photosBefore = try await repository.loadPhotos(for: b.id)
        let analysesBefore = try await repository.loadSavedAnalyses(for: b.id)
        _ = try await repository.deletePlant(a)
        let plants = try await repository.loadPlants(); XCTAssertEqual(plants, [b])
        let eventsAfter = try await repository.loadCareEvents(for: b.id), photosAfter = try await repository.loadPhotos(for: b.id)
        let analysesAfter = try await repository.loadSavedAnalyses(for: b.id)
        XCTAssertEqual(eventsAfter, eventsBefore); XCTAssertEqual(photosAfter, photosBefore); XCTAssertEqual(analysesAfter, analysesBefore)
        let initial = try await repository.loadInitialPhoto(for: b.id), foreign = try await repository.loadPhoto(id: a.id, for: b.id)
        XCTAssertEqual(initial, StorageTestFixture.photo(2)); XCTAssertEqual(foreign, jpeg)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("AdditionalPhotos/\(b.id).jpg").path))
        let reopened = LocalPlantRepository(root: root), reopenedEvents = try await reopened.loadCareEvents(for: b.id)
        let reopenedPhoto = try await reopened.loadPhoto(id: a.id, for: b.id)
        XCTAssertEqual(reopenedEvents, eventsBefore); XCTAssertEqual(reopenedPhoto, jpeg)
    }

    @MainActor
    func testConflictReloadRequiresNewSnapshotAndAbsentReloadShowsRealNotFound() async throws {
        try await seed(); let repository = LocalPlantRepository(root: root)
        let vm = PlantDetailViewModel(id: StorageTestFixture.plant(1).id, loadDetail: LoadPlantDetail(repository: repository),
            loadPhoto: LoadInitialPlantPhoto(repository: repository), update: UpdatePlant(repository: repository))
        vm.deletePlant = DeletePlant(repository: repository); await vm.load(); vm.requestDeletion()
        let changed = try await repository.updatePlant(id: vm.id, name: "Nombre cambiado", location: "Nuevo lugar")
        vm.confirmDeletion()
        for _ in 0..<1000 where vm.deletionState != .failed { try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(vm.deletionError, .conflict); await vm.reloadAfterDeletionFailure()
        guard case .loaded(let canonical) = vm.state else { return XCTFail("Reload did not publish current snapshot") }
        XCTAssertEqual(canonical, changed); XCTAssertEqual(vm.deletionState, .idle)
        vm.requestDeletion(); _ = try await repository.deletePlant(changed); vm.confirmDeletion()
        for _ in 0..<1000 where vm.deletionState != .failed { try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(vm.deletionError, .notFound); await vm.reloadAfterDeletionFailure()
        guard case .notFound = vm.state else { return XCTFail("Absence invented as own commit") }
        XCTAssertEqual(vm.deletionState, .idle)
    }

    private func corrupt(_ kind: Int) throws {
        let container = try ModelContainer(for: PersistedPlant.self, PersistedCareEvent.self, PersistedPlantPhoto.self, PersistedPlantPhotoAnalysis.self,
            configurations: ModelConfiguration(url: root.appendingPathComponent("Plants.store")))
        let context = ModelContext(container)
        switch kind {
        case 0: try context.fetch(FetchDescriptor<PersistedPlant>())[0].photoReference = "../outside.jpg"
        case 1: try context.fetch(FetchDescriptor<PersistedCareEvent>())[0].kind = "unknown"
        case 2: try context.fetch(FetchDescriptor<PersistedPlantPhoto>())[0].photoReference = "../outside.jpg"
        default: try context.fetch(FetchDescriptor<PersistedPlantPhotoAnalysis>())[0].plantID = UUID()
        }
        try context.save()
    }

    @MainActor
    func testDetailAlertBindingCancelDuplicateOwnerDisappearCallbackOnceAndTerminalRetainedConsumers() async throws {
        try await seed(); let repository = LocalPlantRepository(root: root)
        let list = PlantListViewModel(loadPlants: LoadPlants(repository: repository), loadPhoto: LoadInitialPlantPhoto(repository: repository),
            loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository), loadLastWatering: LoadLastWatering(repository: repository))
        let writer = PlantCommitGate(); list.deletePlant = writer
        await list.load()
        let a = list.cards[0], b = list.cards[1]
        await a.load(); await b.load(); a.lastWatering.appear(); b.lastWatering.appear()
        let bImage: AnyObject? = { if case .loaded(let image) = b.photoState { return image }; return nil }()
        let detail = list.detailViewModel(id: a.id)
        detail.makePhotoPager = { plant in PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: repository),
            loadAdditional: LoadPlantPhoto(repository: repository), loadInitial: LoadInitialPlantPhoto(repository: repository), analysisReader: repository) }
        await detail.load()
        let pager = try XCTUnwrap(detail.photoPager)
        detail.hasPresentedEditor = true; detail.requestDeletion()
        XCTAssertEqual(detail.deletionState, .idle); detail.hasPresentedEditor = false
        detail.requestDeletion(); detail.showingDeletionConfirmation = false
        detail.abandonDeletion(); XCTAssertTrue(detail.canAct)
        let canceledCount = await writer.count(); XCTAssertEqual(canceledCount, 0)
        detail.requestDeletion(); detail.showingDeletionConfirmation = false; detail.confirmDeletion(); detail.confirmDeletion()
        await writer.wait(); XCTAssertEqual(detail.deletionState, .deleting)
        XCTAssertNil(detail.editor()); XCTAssertNil(detail.careEditor()); XCTAssertNil(detail.photoEditor()); XCTAssertNil(detail.analysisEditor())
        detail.cancelLoading(); await detail.load()
        await writer.finish(.success(StorageTestFixture.plant(1)))
        for _ in 0..<1000 where detail.deletionState != .deleted { try await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(detail.deletionState, .deleted); XCTAssertNotNil(list.deletionEvent)
        XCTAssertEqual(list.cards.count, 1); XCTAssertTrue(list.cards[0] === b)
        if case .loaded(let image) = b.photoState { XCTAssertTrue(image === bImage) } else { XCTFail() }
        guard case .idle = a.photoState else { return XCTFail("Deleted card retained image") }
        XCTAssertEqual(a.lastWatering.state, .idle); XCTAssertNil(detail.formPhoto); XCTAssertNil(detail.photoPager)
        XCTAssertEqual(pager.cachedImageCount, 0)
        pager.appear(); pager.refresh(); pager.refreshAnalyses(); a.lastWatering.appear(); a.lastWatering.invalidate(); await a.load()
        detail.applyUpdatedPlant(StorageTestFixture.plant(1)); detail.requestDeletion(); detail.confirmDeletion(); await detail.load()
        XCTAssertEqual(detail.deletionState, .deleted); XCTAssertEqual(pager.cachedImageCount, 0)
        let finalCount = await writer.count(); XCTAssertEqual(finalCount, 1)
    }

    @MainActor
    func testStorageRetryLiteralAndAbandonRequiresNewAlertReadFailureNeverRetriesDestructively() async throws {
        try await seed(); let repository = LocalPlantRepository(root: root)
        for error in [PlantDeletionError.storage, .readFailure, .conflict, .notFound] {
            let writer = PlantCommitGate()
            let vm = PlantDetailViewModel(id: StorageTestFixture.plant(1).id, loadDetail: LoadPlantDetail(repository: repository),
                loadPhoto: LoadInitialPlantPhoto(repository: repository), update: UpdatePlant(repository: repository))
            vm.deletePlant = writer; await vm.load(); vm.requestDeletion(); vm.confirmDeletion(); await writer.wait()
            await writer.finish(.failure(error))
            for _ in 0..<1000 where vm.deletionState != .failed { try await Task.sleep(for: .milliseconds(2)) }
            XCTAssertEqual(vm.deletionError, error); XCTAssertEqual(vm.deletionState, .failed)
            if error == .storage {
                vm.confirmDeletion(); await writer.wait(expected: 2)
                let snapshots = await writer.snapshots(); XCTAssertEqual(snapshots, [StorageTestFixture.plant(1), StorageTestFixture.plant(1)])
                await writer.finish(.failure(error))
                for _ in 0..<1000 where vm.deletionState != .failed { try await Task.sleep(for: .milliseconds(2)) }
            } else { vm.confirmDeletion(); let count = await writer.count(); XCTAssertEqual(count, 1) }
            vm.abandonDeletion(); vm.confirmDeletion(); XCTAssertTrue(vm.canAct)
            let expected = error == .storage ? 2 : 1
            let count = await writer.count(); XCTAssertEqual(count, expected)
            vm.requestDeletion(); XCTAssertEqual(vm.deletionState, .confirming)
        }
    }
}

private final class CleanupPlantFault: @unchecked Sendable {
    private let lock = NSLock(); private var calls = 0; let all: Bool
    init(all: Bool) { self.all = all }
    var count: Int { lock.withLock { calls } }
    func run() throws {
        let call = lock.withLock { calls += 1; return calls }
        if all || call == 1 { throw PlantDeletionError.storage }
    }
}

private actor PlantCommitGate: DeletePlantUseCase {
    private var values: [Plant] = []
    private var continuation: CheckedContinuation<Plant, Error>?
    func execute(_ expected: Plant) async throws -> Plant {
        values.append(expected)
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }
    func count() -> Int { values.count }
    func snapshots() -> [Plant] { values }
    func wait(expected: Int = 1) async {
        for _ in 0..<1000 {
            if values.count == expected, continuation != nil { return }
            try? await Task.sleep(for: .milliseconds(2))
        }
    }
    func finish(_ result: Result<Plant, Error>) { continuation?.resume(with: result); continuation = nil }
}
