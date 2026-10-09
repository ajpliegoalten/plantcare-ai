import XCTest

final class PlantCareAIUITests: XCTestCase {
    private var storageIDs: [String] = []

    private func plantID(_ index: Int) -> String { "00000000-0000-0000-0000-00000000000\(index)" }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }

    private func assertCards(_ app: XCUIApplication) {
        for index in 1...2 {
            let card = app.buttons["plantCard-\(plantID(index))"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            reveal(card, in: app)
            let loaded = NSPredicate(format: "value == %@", "Foto cargada")
            expectation(for: loaded, evaluatedWith: card)
            waitForExpectations(timeout: 10)
            XCTAssertEqual(card.label, index == 1 ? "Fixture 1, Monstera deliciosa, Ventana" : "Fixture 2, Monstera deliciosa")
        }
    }

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
        assertCards(app)
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        app.terminate()
        app.launchArguments = ["--storage-test-id", id, "--storage-verify", "-AppleLanguages", "(es)"]
        app.launch()
        assertCards(app)
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        XCTAssertFalse(app.buttons["addPlantHeader"].isEnabled)
    }

    func testPlantCardsSelectCorrectIdentity() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "--storage-seed", "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        for index in 1...2 {
            let card = app.buttons["plantCard-\(plantID(index))"]
            reveal(card, in: app)
            // Photo region of first, text/content region of second.
            let offset = CGVector(dx: 0.5, dy: index == 1 ? 0.25 : 0.85)
            for _ in 0..<8 where card.frame.minY + card.frame.height * offset.dy > app.frame.maxY - 60 {
                app.swipeUp()
            }
            capture("card-\(index)", app: app)
            card.coordinate(withNormalizedOffset: offset).tap()
            let selected = app.staticTexts["selectedPlant-\(plantID(index))"]
            XCTAssertTrue(selected.waitForExistence(timeout: 10))
            XCTAssertEqual(selected.label, "Fixture \(index)")
            capture("selected-\(index)", app: app)
            XCTAssertTrue(app.staticTexts["El detalle de esta planta estará disponible próximamente."].exists)
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(card.waitForExistence(timeout: 10))
        }
    }

    func testPhotoFailureKeepsCardsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "--storage-seed", "--storage-photo-missing", "-AppleLanguages", "(es)"]
        app.launch()
        let first = app.buttons["plantCard-\(plantID(1))"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        let failed = NSPredicate(format: "value == %@", "No se pudo cargar la foto")
        expectation(for: failed, evaluatedWith: first)
        waitForExpectations(timeout: 10)
        capture("photo-failure", app: app)
        XCTAssertEqual(first.label, "Fixture 1, Monstera deliciosa, Ventana")
        let retry = app.buttons["retryPlantPhoto-\(plantID(1))"]
        reveal(retry, in: app)
        retry.tap()
        expectation(for: failed, evaluatedWith: first)
        waitForExpectations(timeout: 10)
        XCTAssertFalse(app.staticTexts["selectedPlant-\(plantID(1))"].exists)
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
        let second = app.buttons["plantCard-\(plantID(2))"]
        reveal(second, in: app)
        expectation(for: NSPredicate(format: "value == %@", "Foto cargada"), evaluatedWith: second)
        waitForExpectations(timeout: 10)
        for _ in 0..<8 where !first.isHittable { app.swipeDown() }
        first.tap()
        XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(1))"].waitForExistence(timeout: 10))
    }

    func testLongCardTextRemainsReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "--storage-seed", "--storage-long-text", "-AppleLanguages", "(es)"]
        app.launch()
        for index in 1...2 {
            let card = app.buttons["plantCard-\(plantID(index))"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            reveal(card, in: app)
            XCTAssertTrue(card.label.contains("Fixture \(index): mi planta junto a la ventana del salón"))
            XCTAssertTrue(card.label.contains("Monstera deliciosa — especie confirmada de este ejemplar"))
            XCTAssertGreaterThanOrEqual(card.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(card.frame.maxX, app.frame.maxX)
            // A card can exceed the viewport at AX sizes: reveal actual text,
            // not a normalized coordinate on an offscreen/full-height frame.
            let content = card.staticTexts[index == 1
                ? "Ventana del salón junto a la estantería de libros"
                : "Monstera deliciosa — especie confirmada de este ejemplar"]
            reveal(content, in: app)
            capture("long-card-\(index)", app: app)
            content.tap()
            XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(index))"].waitForExistence(timeout: 10))
            app.navigationBars.buttons.firstMatch.tap()
        }
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
