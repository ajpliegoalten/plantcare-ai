import XCTest
@testable import PlantCareAI

final class LoadPlantTimelineTests: XCTestCase {
    @MainActor
    func testRealViewSessionScrollRetryRefreshContextNeverCommitsOrChangesBytes() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let writes = TimelineCommitCounter(), plant = StorageTestFixture.plant(1)
        let repository = LocalPlantRepository(root: root, beforeCommit: { writes.record() })
        try await repository.savePlant(plant, initialPhoto: StorageTestFixture.photo(1))
        let prepared = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
        let photo = PlantTimelineFixtureLoad.photo(for: plant.id)
        _ = try await repository.savePhoto(photo, jpeg: prepared.jpeg)
        let before = writes.value
        let failingRead = TimelineOnceFailingImage(repository: repository)
        let photos = PlantTimelinePhotoViewModel(plantID: plant.id, read: { identity, plantID in
            switch identity {
            case .initial: return try await repository.loadInitialPhoto(for: plantID)
            case .additional(let id): return try await failingRead.read(id, plantID)
            case .care: throw PlantStorageError.validation
            }
        })
        let vm = PlantTimelineViewModel(plantID: plant.id,
            load: LoadPlantTimeline(detail: LoadPlantDetail(repository: repository), care: repository, photos: repository), photos: photos)
        func wait(_ condition: () -> Bool) async {
            for _ in 0..<1000 { if condition() { return }; try? await Task.sleep(for: .milliseconds(2)) }; XCTFail("Timed out")
        }
        vm.appear(); await wait { vm.state == .loaded }
        for identity in [PlantTimelineIdentity.initial(plant.id), .additional(photo.id)] {
            photos.show(identity)
            if case .additional = identity {
                await wait { photos.state(for: identity) == .failed }; photos.retry(identity)
            }
            await wait { photos.state(for: identity) == .loaded }
            photos.hide(identity); photos.show(identity); photos.retry(identity)
        }
        vm.updateContext(); vm.foreground(); await wait { vm.state == .loaded }
        photos.show(.additional(photo.id)); await wait { photos.state(for: .additional(photo.id)) == .loaded }
        vm.disappear(); vm.appear(); await wait { vm.state == .loaded }; vm.disappear()
        XCTAssertEqual(writes.value, before)
        let reopened = LocalPlantRepository(root: root)
        let actual = try await reopened.loadPlants(), metadata = try await reopened.loadPhotos(for: plant.id)
        let initial = try await reopened.loadInitialPhoto(for: plant.id), additional = try await reopened.loadPhoto(id: photo.id, for: plant.id)
        XCTAssertEqual(actual, [plant]); XCTAssertEqual(metadata, [photo]); XCTAssertEqual(initial, StorageTestFixture.photo(1)); XCTAssertEqual(additional, prepared.jpeg)
    }
    func testRealStoreUnionAllKindsPhotosPreOriginIdentityAndReadOnlyReopen() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let writes = TimelineCommitCounter()
        let repository = LocalPlantRepository(root: root, beforeCommit: { writes.record() })
        let a = StorageTestFixture.plant(1), b = StorageTestFixture.plant(2)
        try await repository.savePlant(a, initialPhoto: StorageTestFixture.photo(1))
        try await repository.savePlant(b, initialPhoto: StorageTestFixture.photo(2))
        let events = PlantTimelineFixtureLoad.events(for: a.id)
        for event in events.reversed() { _ = try await repository.saveCareEvent(event) }
        let prepared = try await LocalIdentificationPhotoPreparer().prepare(StorageTestFixture.photo(2))
        // Same UUID as a care event must remain a distinct additional-photo identity.
        let photo = PlantPhoto(id: events[0].id, plantID: a.id, occurredAt: Date(timeIntervalSince1970: -172800),
            createdAt: Date(timeIntervalSince1970: 205000), timeZoneIdentifier: "Africa/Abidjan", width: prepared.width, height: prepared.height)
        _ = try await repository.savePhoto(photo, jpeg: prepared.jpeg)
        let before = writes.value
        let useCase = LoadPlantTimeline(detail: LoadPlantDetail(repository: repository), care: repository, photos: repository)
        for _ in 0..<3 {
            let loaded = try await useCase.execute(for: a.id)
            let result = try XCTUnwrap(loaded)
            XCTAssertEqual(Set(result.map(\.id)), Set(events.map { .care($0.id) } + [.initial(a.id), .additional(photo.id)]))
            XCTAssertEqual(result.filter { $0 == .initial(a) }.count, 1)
            XCTAssertTrue(result.contains(.additional(photo)))
            for event in events { XCTAssertTrue(result.contains(.care(event))) }
            XCTAssertTrue(result.allSatisfy { $0.plantID == a.id })
        }
        let bResult = try await useCase.execute(for: b.id), missing = try await useCase.execute(for: UUID())
        XCTAssertEqual(bResult, [.initial(b)]); XCTAssertNil(missing)
        XCTAssertEqual(writes.value, before)
        let plants = try await repository.loadPlants(); XCTAssertEqual(plants, [a, b])
        let bytes = try await repository.loadPhoto(id: photo.id, for: a.id); XCTAssertEqual(bytes, prepared.jpeg)
        for index in 1...2 {
            let bytes = try await repository.loadInitialPhoto(for: StorageTestFixture.plant(index).id)
            XCTAssertEqual(bytes, StorageTestFixture.photo(index))
        }
        let reopened = LocalPlantRepository(root: root)
        let result = try await LoadPlantTimeline(detail: LoadPlantDetail(repository: reopened), care: reopened, photos: reopened).execute(for: a.id)
        XCTAssertEqual(result?.count, 7)
        let reopenedEvents = try await reopened.loadCareEvents(for: a.id), originalEvents = try await repository.loadCareEvents(for: a.id)
        let reopenedPhotos = try await reopened.loadPhotos(for: a.id), reopenedBytes = try await reopened.loadPhoto(id: photo.id, for: a.id)
        XCTAssertEqual(reopenedEvents, originalEvents); XCTAssertEqual(reopenedPhotos, [photo]); XCTAssertEqual(reopenedBytes, prepared.jpeg)
        XCTAssertEqual(writes.value, before)
    }

    func testEveryMetadataFailureThrowsNotPartialAndForeignRowsFilteredNoBytesOrWrites() async throws {
        let repository = TimelineRepositoryDouble()
        let useCase = LoadPlantTimeline(detail: LoadPlantDetail(repository: repository), care: repository, photos: repository)
        for step in 1...3 {
            await repository.setFailure(step)
            do { _ = try await useCase.execute(for: StorageTestFixture.plant(1).id); XCTFail("Must throw at source \(step)") }
            catch { XCTAssertEqual(error as? PlantStorageError, .storage) }
        }
        await repository.setFailure(0)
        let result = try await useCase.execute(for: StorageTestFixture.plant(1).id)
        XCTAssertEqual(result, [.initial(StorageTestFixture.plant(1))])
        let io = await repository.forbiddenIO; XCTAssertEqual(io, 0)
    }
}

private actor TimelineOnceFailingImage {
    let repository: LocalPlantRepository
    private var failed = false
    init(repository: LocalPlantRepository) { self.repository = repository }
    func read(_ id: UUID, _ plantID: UUID) async throws -> Data {
        let bytes = try await repository.loadPhoto(id: id, for: plantID)
        if !failed { failed = true; throw PlantPhotoError.photoMissing }
        return bytes
    }
}

final class TimelineCommitCounter: @unchecked Sendable {
    private let lock = NSLock(); private var count = 0
    func record() { lock.lock(); defer { lock.unlock() }; count += 1 }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}

private actor TimelineRepositoryDouble: PlantRepository, CareEventRepository, PlantPhotoRepository {
    var failure = 0, forbiddenIO = 0
    func setFailure(_ step: Int) { failure = step }
    func loadPlants() throws -> [Plant] { if failure == 1 { throw PlantStorageError.storage }; return [StorageTestFixture.plant(1)] }
    func loadCareEvents(for plantID: UUID) throws -> [CareEvent] {
        if failure == 2 { throw PlantStorageError.storage }
        return PlantTimelineFixtureLoad.events(for: StorageTestFixture.plant(2).id)
    }
    func loadPhotos(for plantID: UUID) throws -> [PlantPhoto] {
        if failure == 3 { throw PlantStorageError.storage }
        return [PlantTimelineFixtureLoad.photo(for: StorageTestFixture.plant(2).id)]
    }
    func loadPhoto(id: UUID, for plantID: UUID) throws -> Data { forbiddenIO += 1; throw PlantStorageError.storage }
    func loadInitialPhoto(for id: UUID) throws -> Data { forbiddenIO += 1; throw PlantStorageError.storage }
    func savePlant(_ plant: Plant, initialPhoto: Data) { forbiddenIO += 1 }
    func updatePlant(id: UUID, name: String, location: String?) throws -> Plant { forbiddenIO += 1; throw PlantStorageError.storage }
    func saveCareEvent(_ event: CareEvent) -> CareEvent { forbiddenIO += 1; return event }
    func savePhoto(_ photo: PlantPhoto, jpeg: Data) -> PlantPhoto { forbiddenIO += 1; return photo }
}
