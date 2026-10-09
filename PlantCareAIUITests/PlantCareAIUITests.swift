import XCTest

final class PlantCareAIUITests: XCTestCase {
    private var storageIDs: [String] = []

    private func isolatedID() -> String {
        let id = UUID().uuidString
        storageIDs.append(id)
        return id
    }

    override func tearDownWithError() throws {
        for id in storageIDs {
            let app = XCUIApplication()
            app.launchArguments = ["--storage-test-id", id, "--storage-cleanup"]
            app.launch()
            XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 10))
            app.terminate()
        }
        storageIDs.removeAll()
    }
    func testStoredCollectionSurvivesProcessRelaunch() {
        let app = XCUIApplication()
        let id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["storedCollectionMessage"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        app.terminate()
        app.launchArguments = ["--storage-test-id", id, "--storage-verify", "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["storedCollectionMessage"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        XCTAssertFalse(app.buttons["addPlantHeader"].isEnabled)
    }

    func testStorageFailureDoesNotShowEmptyCollection() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "--storage-corrupt"]
        app.launch()
        XCTAssertTrue(app.staticTexts["storageErrorMessage"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
    }
    func testCleanLaunchShowsEmptyCollectionAndUnavailableAdd() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launchArguments += ["--storage-test-id", isolatedID()]
        app.launch()

        let title = app.staticTexts["collectionTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Mis plantas")
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["emptyCollectionTitle"].label, "Todavía no tienes plantas")
        XCTAssertTrue(app.staticTexts["Guarda aquí tus plantas para tener sus cuidados a mano."].exists)
        XCTAssertTrue(app.staticTexts["Disponible cuando puedas elegir una foto."].exists)
        let headerAdd = app.buttons["addPlantHeader"]
        let firstAdd = app.buttons["addFirstPlant"]
        XCTAssertTrue(headerAdd.exists)
        XCTAssertTrue(headerAdd.label.contains("Añadir"))
        XCTAssertFalse(headerAdd.isEnabled)
        XCTAssertTrue(firstAdd.exists)
        XCTAssertEqual(firstAdd.label, "Añadir mi primera planta")
        XCTAssertFalse(firstAdd.isEnabled)
        XCTAssertFalse(app.staticTexts["Preparando tu espacio para cuidar plantas."].exists)
        XCTAssertFalse(app.staticTexts["Actividad"].exists)
    }

    func testEnglishPreferenceFallsBackToSpanishInsteadOfKeys() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchArguments += ["--storage-test-id", isolatedID()]
        app.launch()

        let title = app.staticTexts["collectionTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Mis plantas")
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["emptyCollectionTitle"].label, "Todavía no tienes plantas")
        XCTAssertTrue(app.buttons["addFirstPlant"].exists)
        XCTAssertTrue(app.staticTexts["Disponible cuando puedas elegir una foto."].exists)
    }

    func testEmptyCollectionCanScrollToUnavailableAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launchArguments += ["--storage-test-id", isolatedID()]
        app.launch()

        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 10))
        let action = app.buttons["addFirstPlant"]
        XCTAssertTrue(action.exists)
        for _ in 0..<5 where !action.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(action.isHittable)
        XCTAssertFalse(action.isEnabled)
        XCTAssertTrue(app.staticTexts["Disponible cuando puedas elegir una foto."].exists)
    }
}
