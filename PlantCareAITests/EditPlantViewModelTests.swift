import XCTest
@testable import PlantCareAI

@MainActor
final class EditPlantViewModelTests: XCTestCase {
    func testDraftAndNewSessionDoNotWriteAndInvalidDoesNotSave() async {
        let repository = EditRepository(), plant = StorageTestFixture.plant(1)
        let update = UpdatePlant(repository: repository)
        let draft = EditPlantViewModel(plant: plant, update: update) { _ in XCTFail("No save") }
        XCTAssertEqual(draft.name, plant.name)
        XCTAssertEqual(draft.location, plant.location)
        draft.name = " \n"; draft.location = "Borrador"
        XCTAssertFalse(draft.isValid)
        await draft.save()
        let fresh = EditPlantViewModel(plant: plant, update: update) { _ in XCTFail("No save") }
        XCTAssertEqual(fresh.name, plant.name)
        XCTAssertEqual(fresh.location, plant.location)
        let count = await repository.count(); XCTAssertEqual(count, 0)
    }

    func testSingleCommitCapturesDraftAndPublishesOnlyAfterCompletion() async {
        let repository = EditRepository(suspended: true)
        var confirmed: [Plant] = []
        let vm = EditPlantViewModel(plant: StorageTestFixture.plant(1), update: UpdatePlant(repository: repository)) { confirmed.append($0) }
        vm.name = " Mi monstera "; vm.location = " Salón "
        let task = Task { await vm.save() }
        await repository.wait()
        XCTAssertTrue(vm.isSaving); XCTAssertTrue(confirmed.isEmpty)
        // Even a programmatic mutation cannot change the already captured operation.
        vm.name = "Otro borrador"; vm.location = "Otra ubicación"
        await vm.save()
        let count = await repository.count(); XCTAssertEqual(count, 1)
        await repository.release(); await task.value
        XCTAssertEqual(vm.state, .saved)
        XCTAssertEqual(confirmed.count, 1)
        XCTAssertEqual(confirmed[0].name, "Mi monstera")
        XCTAssertEqual(confirmed[0].location, "Salón")
        await vm.save()
        let finalCount = await repository.count(); XCTAssertEqual(finalCount, 1)
    }

    func testErrorRetainsDraftAndRetryAndAbsenceNeverPublishSuccess() async {
        for error: PlantStorageError in [.storage, .notFound] {
            let repository = EditRepository()
            await repository.setError(error)
            var saved: Plant?
            let vm = EditPlantViewModel(plant: StorageTestFixture.plant(1), update: UpdatePlant(repository: repository)) { saved = $0 }
            vm.name = " Nombre nuevo "; vm.location = " Patio "
            await vm.save()
            XCTAssertEqual(vm.state, .error(error)); XCTAssertNil(saved)
            XCTAssertEqual(vm.name, " Nombre nuevo "); XCTAssertEqual(vm.location, " Patio ")
            await repository.setError(nil)
            await vm.save()
            XCTAssertEqual(vm.state, .saved); XCTAssertEqual(saved?.name, "Nombre nuevo")
        }
    }
}
