import XCTest

final class PlantCareAIUITests: XCTestCase {
    private var storageIDs: [String] = []

    private func plantID(_ index: Int) -> String { "00000000-0000-0000-0000-00000000000\(index)" }

    private func back(_ app: XCUIApplication) {
        app.navigationBars.buttons.matching(NSPredicate(format: "identifier == 'Back' OR label == 'Atrás' OR label == 'Back'")).firstMatch.tap()
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<30 where !element.isHittable { app.swipeUp() }
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

    private func assertDetail(_ index: Int, app: XCUIApplication, longCare: Bool = false, photoFailed: Bool = false) {
        let id = plantID(index)
        let selected = app.staticTexts["selectedPlant-\(id)"]
        XCTAssertTrue(selected.waitForExistence(timeout: 10))
        let photo = app.descendants(matching: .any)["detailPhoto-\(id)"].firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "value == %@", photoFailed ? "No se pudo cargar la fotografía" : "Foto cargada"), evaluatedWith: photo)
        waitForExpectations(timeout: 10)
        for _ in 0..<20 where !photo.isHittable { app.swipeDown() }
        capture("detail-photo-\(index)", app: app)
        reveal(selected, in: app)
        XCTAssertTrue(selected.label.hasPrefix("Fixture \(index)"))
        let species = app.staticTexts["detailSpecies-\(id)"]
        reveal(species, in: app)
        XCTAssertTrue(species.label.hasPrefix("Monstera deliciosa"))
        let location = app.descendants(matching: .any)["detailLocation-\(id)"].firstMatch
        XCTAssertEqual(location.exists, index == 1)
        if index == 1 { XCTAssertTrue(location.label.contains("Ventana")) }
        let date = app.staticTexts["detailCreatedAt-\(id)"]
        reveal(date, in: app)
        XCTAssertTrue(date.label.hasPrefix("Guardada el "))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        XCTAssertEqual(date.label, "Guardada el \(formatter.string(from: Date(timeIntervalSince1970: Double(index) * 1000)))")
        XCTAssertFalse(app.staticTexts["El detalle de esta planta estará disponible próximamente."].exists)
        capture("detail-identity-\(index)", app: app)
        let fields = ["light", "watering", "humidity", "temperature", "substrate", "fertilizer"]
        let values = ["Luz", "Riego", "Humedad", "Temperatura", "Sustrato", "Abono"]
        for (field, value) in zip(fields, values) {
            let row = app.descendants(matching: .any)["detailCare-\(field)-\(id)"].firstMatch
            reveal(row, in: app)
            XCTAssertTrue(row.label.contains("\(value) \(index)"), row.label)
            XCTAssertFalse(row.label.contains("detail.care."), row.label)
            XCTAssertTrue(row.label.hasPrefix(field == "fertilizer" ? "Abonado" : value), row.label)
            XCTAssertFalse(row.label.contains("\(value) \(3 - index)"), row.label)
            if longCare { XCTAssertTrue(row.label.contains("sin interpretar esta ficha como un diagnóstico.")) }
            XCTAssertGreaterThanOrEqual(row.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(row.frame.maxX, app.frame.maxX)
            capture("detail-care-\(field)-\(index)", app: app)
        }
        let disclaimer = app.staticTexts["detailDisclaimer"]
        reveal(disclaimer, in: app)
        XCTAssertEqual(disclaimer.label, "Estos cuidados son orientativos y no constituyen un diagnóstico.")
        capture("detail-bottom-\(index)", app: app)
        XCTAssertFalse(app.staticTexts["selectedPlant-\(plantID(3 - index))"].exists)
    }

    private func openAndCheckBothDetails(_ app: XCUIApplication) {
        for index in 1...2 {
            let card = app.buttons["plantCard-\(plantID(index))"]
            for _ in 0..<15 where !card.isHittable { app.swipeDown() }
            reveal(card, in: app)
            card.tap()
            assertDetail(index, app: app)
            back(app)
        }
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
        openAndCheckBothDetails(app)
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        app.terminate()
        app.launchArguments = ["--storage-test-id", id, "--storage-verify", "-AppleLanguages", "(es)"]
        app.launch()
        assertCards(app)
        openAndCheckBothDetails(app)
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        XCTAssertFalse(app.buttons["addPlantHeader"].isEnabled)
    }

    private func openEditor(_ index: Int, app: XCUIApplication) {
        let card = app.buttons["plantCard-\(plantID(index))"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        for _ in 0..<15 where !card.isHittable { app.swipeDown() }
        reveal(card, in: app); card.tap()
        let edit = app.buttons["editPlant-\(plantID(index))"]
        XCTAssertTrue(edit.waitForExistence(timeout: 10)); edit.tap()
        XCTAssertTrue(app.navigationBars["Editar planta"].waitForExistence(timeout: 10))
    }

    private func replace(_ id: String, with value: String, app: XCUIApplication) {
        let field = app.textViews[id].exists ? app.textViews[id] : app.textFields[id]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        // A field can report hittable while its center is under the sticky bar.
        // Move the form itself, not the sheet's drag handle, back into view.
        for _ in 0..<6 where field.frame.midY < app.navigationBars["Editar planta"].frame.maxY + 44 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.4))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.75)))
        }
        field.tap() // XCTest scrolls the native field into view, including from above.
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let old = field.value as? String ?? ""
        if !old.isEmpty {
            // Native triple tap selects the fixture's single text paragraph.
            field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            field.typeText(value.isEmpty ? XCUIKeyboardKey.delete.rawValue : value)
        } else { field.typeText(value) }
        XCTAssertEqual(field.value as? String, value)
    }

    private func saveEditor(_ app: XCUIApplication) {
        app.buttons["saveEditPlant"].tap()
        XCTAssertTrue(app.navigationBars["Editar planta"].waitForNonExistence(timeout: 10))
    }

    private func finishTyping(_ app: XCUIApplication) {
        app.buttons["dismissEditPlantKeyboard"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    }

    func testEditPersistsAndRefreshesOnlySelectedPlant() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "-AppleLanguages", "(es)"]
        app.launch()
        openEditor(1, app: app)
        XCTAssertTrue(app.staticTexts["Nombre personalizado"].exists)
        XCTAssertTrue(app.staticTexts["Ubicación (opcional)"].exists)
        capture("edit-form", app: app)
        replace("editPlantName", with: "Mi monstera", app: app)
        replace("editPlantLocation", with: "Salón", app: app)
        saveEditor(app)
        let name = app.staticTexts["selectedPlant-\(plantID(1))"]
        XCTAssertTrue(name.waitForExistence(timeout: 10)); reveal(name, in: app)
        XCTAssertEqual(name.label, "Mi monstera")
        let location = app.descendants(matching: .any)["detailLocation-\(plantID(1))"].firstMatch
        XCTAssertTrue(location.label.contains("Salón"))
        capture("edit-confirmed-detail", app: app)
        back(app)
        XCTAssertEqual(app.buttons["plantCard-\(plantID(1))"].label, "Mi monstera, Monstera deliciosa, Salón")
        XCTAssertEqual(app.buttons["plantCard-\(plantID(2))"].label, "Fixture 2, Monstera deliciosa")
        openEditor(1, app: app)
        let reopenedName = app.textViews["editPlantName"].exists ? app.textViews["editPlantName"] : app.textFields["editPlantName"]
        XCTAssertEqual(reopenedName.value as? String, "Mi monstera")
        app.buttons["cancelEditPlant"].tap(); back(app)
        let untouched = app.buttons["plantCard-\(plantID(2))"]; reveal(untouched, in: app); untouched.tap()
        assertDetail(2, app: app); back(app)
        app.terminate()
        app.launchArguments = ["--storage-test-id", id, "--storage-verify-edited", "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
        openEditor(1, app: app)
        let field = app.textViews["editPlantName"].exists ? app.textViews["editPlantName"] : app.textFields["editPlantName"]
        XCTAssertEqual(field.value as? String, "Mi monstera")
        app.buttons["cancelEditPlant"].tap(); back(app)
        let second = app.buttons["plantCard-\(plantID(2))"]; reveal(second, in: app); second.tap()
        assertDetail(2, app: app)
    }

    func testCancelGestureValidationAndOptionalLocationWithMissingPhoto() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--storage-photo-missing", "-AppleLanguages", "(es)"]
        app.launch(); openEditor(1, app: app)
        replace("editPlantName", with: "Descartar", app: app)
        app.buttons["cancelEditPlant"].tap()
        app.buttons["editPlant-\(plantID(1))"].tap()
        let field = app.textViews["editPlantName"].exists ? app.textViews["editPlantName"] : app.textFields["editPlantName"]
        XCTAssertEqual(field.value as? String, "Fixture 1")
        replace("editPlantLocation", with: "No guardar", app: app)
        finishTyping(app)
        // Drag the sheet's top edge, not the scrolling form or keyboard.
        for _ in 0..<3 where app.navigationBars["Editar planta"].exists {
            app.navigationBars["Editar planta"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).withOffset(CGVector(dx: 0, dy: -8)).press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)), withVelocity: .slow, thenHoldForDuration: 0)
        }
        XCTAssertTrue(app.navigationBars["Editar planta"].waitForNonExistence(timeout: 10))
        app.buttons["editPlant-\(plantID(1))"].tap()
        let originalLocation = app.textViews["editPlantLocation"].exists ? app.textViews["editPlantLocation"] : app.textFields["editPlantLocation"]
        XCTAssertEqual(originalLocation.value as? String, "Ventana")
        replace("editPlantName", with: " ", app: app)
        finishTyping(app)
        XCTAssertFalse(app.buttons["saveEditPlant"].isEnabled)
        let validation = app.staticTexts["editPlantValidation"]
        // Swipe inside the visible form, above the keyboard; app.swipeUp starts on keys.
        for _ in 0..<20 where !validation.isHittable {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.2)))
        }
        XCTAssertTrue(validation.isHittable)
        XCTAssertEqual(validation.label, "Introduce un nombre para esta planta.")
        capture("edit-invalid", app: app)
        replace("editPlantName", with: "Fixture 1", app: app)
        replace("editPlantLocation", with: "", app: app)
        saveEditor(app)
        XCTAssertTrue(app.buttons["editPlant-\(plantID(1))"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["detailLocation-\(plantID(1))"].firstMatch.exists)
        back(app)
        XCTAssertEqual(app.buttons["plantCard-\(plantID(1))"].label, "Fixture 1, Monstera deliciosa")
        openEditor(2, app: app)
        replace("editPlantLocation", with: "Patio", app: app)
        saveEditor(app)
        XCTAssertTrue(app.buttons["editPlant-\(plantID(2))"].waitForExistence(timeout: 10))
        let location = app.descendants(matching: .any)["detailLocation-\(plantID(2))"].firstMatch
        reveal(location, in: app); XCTAssertTrue(location.label.contains("Patio"))
    }

    func testPlantCardsSelectCorrectIdentity() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "--storage-seed", "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        for index in [1, 2, 1] {
            let card = app.buttons["plantCard-\(plantID(index))"]
            for _ in 0..<15 where !card.isHittable { app.swipeDown() }
            reveal(card, in: app)
            // Photo region of first, text/content region of second.
            let offset = CGVector(dx: 0.5, dy: index == 1 ? 0.25 : 0.85)
            for _ in 0..<15 {
                let targetY = card.frame.minY + card.frame.height * offset.dy
                if targetY < app.frame.minY + 100 { app.swipeDown() }
                else if targetY > app.frame.maxY - 60 { app.swipeUp() }
                else { break }
            }
            capture("card-\(index)", app: app)
            card.coordinate(withNormalizedOffset: offset).tap()
            let selected = app.staticTexts["selectedPlant-\(plantID(index))"]
            XCTAssertTrue(selected.waitForExistence(timeout: 10))
            XCTAssertEqual(selected.label, "Fixture \(index)")
            capture("selected-\(index)", app: app)
            assertDetail(index, app: app)
            back(app)
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
        let error = app.staticTexts["detailPhotoError-\(plantID(1))"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        let detailRetry = app.buttons["retryDetailPhoto-\(plantID(1))"]
        reveal(detailRetry, in: app)
        XCTAssertGreaterThanOrEqual(detailRetry.frame.height, 44)
        detailRetry.tap()
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        capture("detail-photo-failure", app: app)
        assertDetail(1, app: app, photoFailed: true)
        back(app)
        reveal(second, in: app)
        second.tap()
        XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(2))"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["detailPhotoError-\(plantID(2))"].exists)
        assertDetail(2, app: app)
    }

    func testLongCardTextRemainsReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "--storage-seed", "--storage-long-text", "--storage-long-care", "-AppleLanguages", "(es)"]
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
            assertDetail(index, app: app, longCare: true)
            back(app)
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
        app.terminate()
        app.launchArguments += ["--storage-seed"]
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        app.buttons["plantCard-\(plantID(1))"].tap()
        XCTAssertTrue(app.navigationBars["Detalle de planta"].waitForExistence(timeout: 10))
        assertDetail(1, app: app)
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
