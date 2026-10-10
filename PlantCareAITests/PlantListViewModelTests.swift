import XCTest
@testable import PlantCareAI

private struct ListResult: LoadPlantsUseCase {
    let result: Result<[Plant], Error>
    func execute() async throws -> [Plant] { try result.get() }
}

@MainActor
final class PlantListViewModelTests: XCTestCase {
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
