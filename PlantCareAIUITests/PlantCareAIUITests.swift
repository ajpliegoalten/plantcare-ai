import XCTest

final class PlantCareAIUITests: XCTestCase {
    func testCleanLaunchShowsEmptyCollectionAndUnavailableAdd() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        let title = app.staticTexts["collectionTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Mis plantas")
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
        app.launch()

        let title = app.staticTexts["collectionTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Mis plantas")
        XCTAssertEqual(app.staticTexts["emptyCollectionTitle"].label, "Todavía no tienes plantas")
        XCTAssertTrue(app.buttons["addFirstPlant"].exists)
        XCTAssertTrue(app.staticTexts["Disponible cuando puedas elegir una foto."].exists)
    }

    func testEmptyCollectionCanScrollToUnavailableAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout: 10))
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
