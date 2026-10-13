import XCTest
@testable import PlantCareAI

private struct ListResult: LoadPlantsUseCase {
    let result: Result<[Plant], Error>
    func execute() async throws -> [Plant] { try result.get() }
}

private actor CreationListLoader: LoadPlantsUseCase {
    let plants: [Plant]
    var calls = 0
    var held: CheckedContinuation<[Plant], Never>?
    init(plants: [Plant]) { self.plants = plants }
    func execute() async throws -> [Plant] {
        calls += 1
        if calls == 1 { return await withCheckedContinuation { held = $0 } }
        return plants
    }
    func release() { held?.resume(returning: []); held = nil }
}

@MainActor
final class PlantListViewModelTests: XCTestCase {
    func testHistoryDeletionReusesVisibleDetailAndInvalidatesOnlyOwnWateringConsumersAndPager() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalPlantRepository(root: root), fixture = try await HistoryDeletionSeed.make(repository)
        let model = PlantListViewModel(loadPlants: LoadPlants(repository: repository), loadPhoto: LoadInitialPlantPhoto(repository: repository),
            loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository), loadLastWatering: LoadLastWatering(repository: repository))
        model.makePhotoPager = { plant in PlantPhotoPagerViewModel(plant: plant, loadMetadata: LoadPlantPhotos(repository: repository),
            loadAdditional: LoadPlantPhoto(repository: repository), loadInitial: LoadInitialPlantPhoto(repository: repository)) }
        await model.load(); let cards = model.cards
        cards.forEach { $0.lastWatering.appear() }
        let detail = model.detailViewModel(id: fixture.plant.id); await detail.load()
        XCTAssertTrue(model.detailViewModel(id: fixture.plant.id) === detail)
        for _ in 0..<1000 {
            if detail.lastWatering.state == .loaded(fixture.events[0].occurredAt), cards[0].lastWatering.state == .loaded(fixture.events[0].occurredAt) { break }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTAssertEqual(detail.lastWatering.state, .loaded(fixture.events[0].occurredAt))
        let other = cards[1].lastWatering.state
        detail.cancelLoading(preservingPhotoSelection: true)
        _ = try await repository.deleteCareEvent(fixture.events[0]); model.applyHistoryDeletion(.care(fixture.events[0]))
        await detail.load()
        for _ in 0..<1000 {
            if detail.lastWatering.state == .loaded(nil), cards[0].lastWatering.state == .loaded(nil) { break }
            try? await Task.sleep(for: .milliseconds(2))
        }
        XCTAssertEqual(detail.lastWatering.state, .loaded(nil)); XCTAssertEqual(cards[0].lastWatering.state, .loaded(nil))
        XCTAssertEqual(cards[1].lastWatering.state, other)
        let pager = try XCTUnwrap(detail.photoPager)
        for _ in 0..<1000 { if pager.isComplete { break }; try? await Task.sleep(for: .milliseconds(2)) }
        pager.select(.additional(fixture.photo.id)); detail.cancelLoading(preservingPhotoSelection: true)
        _ = try await repository.deletePhoto(fixture.photo); model.applyHistoryDeletion(.additional(fixture.photo))
        XCTAssertEqual(pager.selected, .initial(fixture.plant.id)); XCTAssertEqual(pager.descriptors.count, 1)
        XCTAssertEqual(cards[0].lastWatering.state, .loaded(nil))
        XCTAssertTrue(model.cards[0] === cards[0]); XCTAssertTrue(detail.photoPager === pager)
        cards.forEach { $0.lastWatering.disappear() }; detail.cancelLoading()
    }
    func testWateringInjectionCommitsOnlyEventAndPreservesCardsMetadataAndCachedImage() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalPlantRepository(root: root)
        for index in 1...2 { try await repository.savePlant(StorageTestFixture.plant(index), initialPhoto: StorageTestFixture.photo(index)) }
        let model = PlantListViewModel(loadPlants: LoadPlants(repository: repository), loadPhoto: LoadInitialPlantPhoto(repository: repository),
            loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository), registerCare: RegisterCareEvent(repository: repository), loadLastWatering: LoadLastWatering(repository: repository))
        await model.load()
        let cards = model.cards
        cards.forEach { $0.lastWatering.appear() }
        for _ in 0..<1000 { if cards.allSatisfy({ $0.lastWatering.state == .loaded(nil) }) { break }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(cards[0].lastWatering.state, .loaded(nil)); XCTAssertEqual(cards[1].lastWatering.state, .loaded(nil))
        await cards[0].load()
        guard case .loaded(let image) = cards[0].photoState else { return XCTFail() }
        let detail = model.detailViewModel(id: cards[0].id)
        XCTAssertNil(detail.careEditor())
        await detail.load()
        let watering = try XCTUnwrap(detail.careEditor()); watering.selectKind(.watering); await watering.save()
        XCTAssertEqual(watering.state, .saved)
        let date = try XCTUnwrap(detail.careConfirmation?.occurredAt)
        for _ in 0..<1000 { if detail.lastWatering.state == .loaded(date), cards[0].lastWatering.state == .loaded(date) { break }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(detail.lastWatering.state, .loaded(date)); XCTAssertEqual(cards[0].lastWatering.state, .loaded(date))
        XCTAssertEqual(cards[1].lastWatering.state, .loaded(nil))
        let retroactive = try XCTUnwrap(detail.careEditor()); retroactive.selectKind(.watering); retroactive.selectDay(offset: -1); await retroactive.save()
        for _ in 0..<1000 { if detail.lastWatering.state == .loaded(date), cards[0].lastWatering.state == .loaded(date) { break }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(detail.lastWatering.state, .loaded(date)); XCTAssertEqual(cards[0].lastWatering.state, .loaded(date))
        let otherCare = try XCTUnwrap(detail.careEditor()); otherCare.selectKind(.fertilizing); await otherCare.save()
        XCTAssertEqual(detail.lastWatering.state, .loaded(date)); XCTAssertEqual(cards[0].lastWatering.state, .loaded(date))
        XCTAssertTrue(model.cards[0] === cards[0]); XCTAssertTrue(model.cards[1] === cards[1])
        guard case .loaded(let retained) = cards[0].photoState else { return XCTFail() }
        XCTAssertTrue(image === retained)
        guard case .loaded(let plants) = model.state else { return XCTFail() }
        XCTAssertEqual(plants, (1...2).map(StorageTestFixture.plant))
        let events = try await repository.loadCareEvents(for: cards[0].id)
        XCTAssertEqual(events.count, 3); XCTAssertTrue(events.contains(try XCTUnwrap(detail.careConfirmation)))
        let other = try await repository.loadCareEvents(for: cards[1].id); XCTAssertEqual(other, [])
        cards.forEach { $0.lastWatering.disappear() }; detail.cancelLoading()
    }
    func testCreatedPlantKeepsExistingCardsAndPhotoStatesOrdersAndDeduplicatesCallback() async {
        let repository = CardPhotoRepository()
        let plants = (1...2).map(StorageTestFixture.plant)
        let model = PlantListViewModel(loadPlants: ListResult(result: .success(plants)), loadPhoto: LoadInitialPlantPhoto(repository: repository), loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository))
        await model.load()
        let originals = model.cards
        let photoTask = Task { await originals[0].load() }
        await repository.waitForRequests(1)
        await repository.resolve(0, .failure(PlantStorageError.photoMissing))
        await photoTask.value
        let added = Plant(id: UUID(), name: "Ficus", confirmedSpecies: "Ficus", createdAt: plants[0].createdAt.addingTimeInterval(-1), location: nil, careSheet: plants[0].careSheet)
        model.applyCreatedPlant(added); model.applyCreatedPlant(added)
        XCTAssertEqual(model.cards.map(\.id), [added.id] + plants.map(\.id))
        XCTAssertTrue(model.cards[1] === originals[0]); XCTAssertTrue(model.cards[2] === originals[1])
        guard case .failed = originals[0].photoState else { return XCTFail("Photo state reset") }
        let reads = await repository.ids(); XCTAssertEqual(reads, [plants[0].id])
        XCTAssertEqual(model.newlyAddedPlantID, added.id)
    }

    func testCommitWhileInitialLoadPendingRefreshesFullMetadataAndRejectsLateEmptyResult() async {
        let plants = (1...2).map(StorageTestFixture.plant)
        let loader = CreationListLoader(plants: plants), repository = CardPhotoRepository()
        let model = PlantListViewModel(loadPlants: loader, loadPhoto: LoadInitialPlantPhoto(repository: repository), loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository))
        let initial = Task { await model.load() }
        for _ in 0..<100 { if await loader.calls == 1 { break }; await Task.yield() }
        model.applyCreatedPlant(plants[1])
        for _ in 0..<1000 { if model.cards.count == 2 { break }; try? await Task.sleep(for: .milliseconds(2)) }
        XCTAssertEqual(model.cards.map(\.id), plants.map(\.id))
        await loader.release(); await initial.value
        XCTAssertEqual(model.cards.map(\.id), plants.map(\.id))
        let reads = await repository.ids(); XCTAssertTrue(reads.isEmpty)
    }
    func testConfirmedUpdateChangesOnlyMatchingSnapshotAndKeepsCardAndImage() async throws {
        let repository = EditRepository()
        let plants = (1...2).map(StorageTestFixture.plant)
        let model = PlantListViewModel(loadPlants: ListResult(result: .success(plants)), loadPhoto: LoadInitialPlantPhoto(repository: repository), loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository))
        await model.load()
        let card = model.cards[0], second = model.cards[1]
        await card.load() // Missing photo is also preserved by metadata edits.
        let detail = model.detailViewModel(id: plants[0].id)
        await detail.load()
        let editor = try XCTUnwrap(detail.editor())
        editor.name = "Mi monstera"; editor.location = "Salón"
        await editor.save()
        XCTAssertTrue(model.cards[0] === card); XCTAssertTrue(model.cards[1] === second)
        XCTAssertEqual(card.plant.name, "Mi monstera"); XCTAssertEqual(card.plant.location, "Salón")
        XCTAssertEqual(second.plant, plants[1])
        guard case .failed = card.photoState, case .failed = detail.photoState else { return XCTFail("Photo state changed") }
        guard case .loaded(let updated) = detail.state, case .loaded(let list) = model.state else { return XCTFail("Commit not reflected") }
        XCTAssertEqual(updated, card.plant); XCTAssertEqual(list, [updated, plants[1]])
    }
    func testListDoesNotReadPhotosAndPreservesStableUUIDModels() async {
        let repository = CardPhotoRepository()
        let plants = (1...2).map(StorageTestFixture.plant)
        let model = PlantListViewModel(loadPlants: ListResult(result: .success(plants)), loadPhoto: LoadInitialPlantPhoto(repository: repository), loadDetail: LoadPlantDetail(repository: repository), update: UpdatePlant(repository: repository))
        await model.load()
        let ids = await repository.ids()
        XCTAssertTrue(ids.isEmpty)
        XCTAssertEqual(model.cards.map(\.id), plants.map(\.id))
        XCTAssertEqual(model.selectedPlant(id: plants[1].id), plants[1])
        XCTAssertNil(model.selectedPlant(id: UUID()))
        let card = model.cards[0]
        await model.load() // Navigation back / repeated task does not replace cards.
        XCTAssertTrue(model.cards[0] === card)
    }

    func testEmptyAndStorageFailureRemainDistinct() async {
        let photo = LoadInitialPlantPhoto(repository: CardPhotoRepository())
        let detail = LoadPlantDetail(repository: CardPhotoRepository())
        let empty = PlantListViewModel(loadPlants: ListResult(result: .success([])), loadPhoto: photo, loadDetail: detail, update: UpdatePlant(repository: CardPhotoRepository()))
        await empty.load()
        guard case .loaded(let plants) = empty.state else { return XCTFail("Not empty") }
        XCTAssertTrue(plants.isEmpty)
        XCTAssertTrue(empty.cards.isEmpty)
        let failed = PlantListViewModel(loadPlants: ListResult(result: .failure(PlantStorageError.storage)), loadPhoto: photo, loadDetail: detail, update: UpdatePlant(repository: CardPhotoRepository()))
        await failed.load()
        guard case .failed = failed.state else { return XCTFail("Failure hidden") }
        XCTAssertTrue(failed.cards.isEmpty)
    }
}
