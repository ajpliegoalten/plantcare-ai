import XCTest
@testable import PlantCareAI

private struct ListResult: LoadPlantsUseCase {
    let result: Result<[Plant], Error>
    func execute() async throws -> [Plant] { try result.get() }
}

@MainActor
final class PlantListViewModelTests: XCTestCase {
    func testListDoesNotReadPhotosAndPreservesStableUUIDModels() async {
        let repository = CardPhotoRepository()
        let plants = (1...2).map(StorageTestFixture.plant)
        let model = PlantListViewModel(loadPlants: ListResult(result: .success(plants)), loadPhoto: LoadInitialPlantPhoto(repository: repository))
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
        let empty = PlantListViewModel(loadPlants: ListResult(result: .success([])), loadPhoto: photo)
        await empty.load()
        guard case .loaded(let plants) = empty.state else { return XCTFail("Not empty") }
        XCTAssertTrue(plants.isEmpty)
        XCTAssertTrue(empty.cards.isEmpty)
        let failed = PlantListViewModel(loadPlants: ListResult(result: .failure(PlantStorageError.storage)), loadPhoto: photo)
        await failed.load()
        guard case .failed = failed.state else { return XCTFail("Failure hidden") }
        XCTAssertTrue(failed.cards.isEmpty)
    }
}
