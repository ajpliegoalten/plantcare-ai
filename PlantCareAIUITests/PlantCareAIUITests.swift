import XCTest

// XCTest schedules classes independently. Shared helpers contain no test methods.
class PlantCareAIUITestCase: XCTestCase {
    private var storageIDs: [String] = []

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    fileprivate func plantID(_ index: Int) -> String { "00000000-0000-0000-0000-00000000000\(index)" }

    fileprivate func back(_ app: XCUIApplication) {
        app.navigationBars.buttons.matching(NSPredicate(format: "identifier == 'Back' OR label == 'Atrás' OR label == 'Back'")).firstMatch.tap()
    }

    fileprivate func capture(_ name: String, app: XCUIApplication) {
        // XCTest still records failures. Opt in to successful screenshots only
        // for a visual review, rather than exporting every row in every test.
        guard ProcessInfo.processInfo.environment["UI_TEST_SCREENSHOTS"] == "1" else { return }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    fileprivate func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }

    fileprivate func revealAboveInPhoto(_ element: XCUIElement, app: XCUIApplication) {
        // Scroll within content only and stop at the target. Repeated application-wide
        // swipeDown at the top can become UISheet's native dismiss gesture.
        let bar = app.navigationBars["Foto de tu planta"]
        for _ in 0..<8 {
            if element.isHittable && element.frame.midY > bar.frame.maxY + 44 { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.4))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.7)))
        }
        XCTAssertTrue(bar.exists)
        XCTAssertTrue(element.isHittable)
    }

    fileprivate func revealInPhoto(_ element: XCUIElement, app: XCUIApplication, gutterX: CGFloat = 0.95) {
        // isHittable alone can report a target behind UISheet's top overlay. Move
        // in either direction until its real tap center is in unobscured content.
        let bar = app.navigationBars["Foto de tu planta"]
        XCTAssertTrue(bar.exists)
        for _ in 0..<8 {
            let y = element.frame.midY
            if element.isHittable && y > bar.frame.maxY + 60 && y < app.frame.maxY - 70 { break }
            let down = y <= bar.frame.maxY + 60
            let origin = app.coordinate(withNormalizedOffset: CGVector(dx: gutterX, dy: down ? 0.4 : 0.7))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: gutterX, dy: down ? 0.62 : 0.48))
            origin.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(element.isHittable)
        XCTAssertGreaterThan(element.frame.midY, bar.frame.maxY + 60)
        XCTAssertLessThan(element.frame.midY, app.frame.maxY - 70)
    }

    fileprivate func dismissPhotoByDrag(_ app: XCUIApplication, capturePrefix: String) {
        let bar = app.navigationBars["Foto de tu planta"]
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        XCTAssertTrue(bar.isHittable)
        // swipeDown on a 54 pt NavigationBar provides too short an element-relative
        // path to reliably finish UISheet's interactive dismissal. Start in the
        // visible, trailing bar area (away from Cancelar), then drag down the screen.
        let origin = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let destination = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.9))
        XCTAssertTrue(bar.frame.contains(origin.screenPoint))
        XCTAssertTrue(app.frame.contains(destination.screenPoint))
        capture("\(capturePrefix)-before", app: app)
        origin.press(forDuration: 0.05, thenDragTo: destination)
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["addPlantHeader"].isHittable)
        XCTAssertTrue(app.buttons["addFirstPlant"].isHittable)
        capture("\(capturePrefix)-dismissed", app: app)
    }

    fileprivate func assertCards(_ app: XCUIApplication) {
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

    fileprivate func isolatedID() -> String {
        let id = UUID().uuidString
        storageIDs.append(id)
        return id
    }

    fileprivate func assertDetail(_ index: Int, app: XCUIApplication, longCare: Bool = false, photoFailed: Bool = false) {
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

    fileprivate func openAndCheckBothDetails(_ app: XCUIApplication) {
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
        XCUIApplication().terminate()
        if let id = storageIDs.first {
            let app = XCUIApplication()
            app.launchArguments = ["--storage-test-id", id, "--storage-cleanup", "--test-cleanup-ids", storageIDs.joined(separator: ",")]
            app.launch()
            XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 10))
            app.terminate()
        }
        storageIDs.removeAll()
    }
    fileprivate func prepareConsentPhoto(_ app: XCUIApplication) {
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["identifyPhoto"].isEnabled)
        XCTAssertFalse(app.navigationBars["Antes de usar IA externa"].exists)
        let a = app.buttons["fixture-photo-A"]
        // The fixture is below the fold. Never swipe the whole application:
        // a lost sheet/process must fail preparation, not scroll a replacement UI.
        let bar = app.navigationBars["Foto de tu planta"]
        let content = app.scrollViews.firstMatch
        guard a.waitForExistence(timeout: 5), content.exists else {
            XCTFail("Photo fixture/content missing before preparation")
            return
        }
        for _ in 0..<15 {
            guard app.state == .runningForeground, bar.exists, content.exists, a.exists else {
                XCTFail("Photo sheet/process disappeared during preparation")
                return
            }
            if a.isHittable && a.frame.midY > bar.frame.maxY + 44 && a.frame.midY < app.frame.maxY - 70 { break }
            content.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.75))
                .press(forDuration: 0.05, thenDragTo: content.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.45)))
        }
        guard bar.exists, a.isHittable,
              a.frame.midY > bar.frame.maxY + 44, a.frame.midY < app.frame.maxY - 70 else {
            XCTFail("Photo fixture is not in unobscured sheet content")
            return
        }
        a.tap()
        XCTAssertTrue(app.images["identificationPhotoPreview"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
    }

    fileprivate func requestConsent(_ app: XCUIApplication) {
        let identify = app.buttons["identifyPhoto"]
        reveal(identify, in: app); XCTAssertTrue(identify.isEnabled); identify.tap()
        XCTAssertTrue(app.navigationBars["Antes de usar IA externa"].waitForExistence(timeout: 5))
    }

    fileprivate func assertInvocations(_ count: Int, app: XCUIApplication) {
        let text = app.staticTexts["externalAIInvocationCount"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label == %@", "Instrumented invocations: \(count)"), evaluatedWith: text)
        waitForExpectations(timeout: 5)
    }

}

final class ExternalConsentUITests: PlantCareAIUITestCase {
    func testExternalConsentCancelGestureAcceptRememberAndRelaunch() {
        let app = XCUIApplication()
        let id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--consent-spy", "--identification-photo-fixture", "-AppleLanguages", "(es)"]
        app.launch()
        prepareConsentPhoto(app); assertInvocations(0, app: app)
        requestConsent(app)
        capture("consent-first-notice", app: app)
        let body = app.staticTexts["externalAIConsentBody"]
        XCTAssertTrue(body.label.contains("proveedor externo"))
        XCTAssertTrue(body.label.contains("especie, cuidados, historial pertinente y tu pregunta"))
        XCTAssertTrue(body.label.contains("No se envía toda tu colección ni fotos antiguas"))
        XCTAssertTrue(body.label.contains("Recordaremos tu aceptación en este dispositivo"))
        XCTAssertFalse(body.label.contains("externalAIConsent."))
        let accept = app.buttons["acceptExternalAIConsent"]
        reveal(accept, in: app)
        XCTAssertEqual(accept.label, "Aceptar y continuar")
        XCTAssertGreaterThanOrEqual(accept.frame.height, 44)
        capture("consent-full-notice-actions", app: app)
        app.buttons["cancelExternalAIConsent"].tap()
        XCTAssertTrue(app.navigationBars["Antes de usar IA externa"].waitForNonExistence(timeout: 5))
        assertInvocations(0, app: app)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        requestConsent(app)
        let bar = app.navigationBars["Antes de usar IA externa"]
        let origin = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.95))
        origin.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        assertInvocations(0, app: app)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        requestConsent(app)
        // Terminating while confirmation is pending must not persist acceptance.
        app.terminate(); app.launch()
        prepareConsentPhoto(app); assertInvocations(0, app: app)
        requestConsent(app)
        reveal(accept, in: app); accept.tap()
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        assertInvocations(1, app: app)
        let identify = app.buttons["identifyPhoto"]
        reveal(identify, in: app); identify.tap()
        assertInvocations(2, app: app)
        XCTAssertFalse(bar.exists)
        app.buttons["cancelIdentificationPhoto"].tap()
        prepareConsentPhoto(app); assertInvocations(2, app: app)
        reveal(identify, in: app); identify.tap(); assertInvocations(3, app: app)
        app.terminate(); app.launch()
        prepareConsentPhoto(app); assertInvocations(0, app: app)
        reveal(identify, in: app); identify.tap(); assertInvocations(1, app: app)
        XCTAssertFalse(bar.exists)
        capture("consent-remembered-after-relaunch", app: app)
        app.terminate()
        let fresh = isolatedID()
        app.launchArguments = ["--storage-test-id", fresh, "--consent-test-id", fresh, "--consent-spy", "--identification-photo-fixture"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        app.buttons["cancelExternalAIConsent"].tap(); assertInvocations(0, app: app)
    }

    func testExternalConsentUnavailableAndBothPlantsUnchanged() {
        let app = XCUIApplication()
        let id = isolatedID()
        // Real production continuation (no spy) with isolated preference and local storage.
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--consent-test-id", id, "--identification-photo-fixture", "--identification-no-configuration", "-AppleLanguages", "(en)"]
        app.launch(); assertCards(app)
        prepareConsentPhoto(app)
        let identify = app.buttons["identifyPhoto"]
        reveal(identify, in: app); identify.tap()
        XCTAssertFalse(app.navigationBars["Antes de usar IA externa"].exists)
        let unavailable = app.staticTexts["externalAIUnavailable"]
        XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        XCTAssertFalse(app.buttons["confirmSpecies"].exists)
        reveal(unavailable, in: app)
        XCTAssertEqual(unavailable.label, "La configuración de identificación no es válida o está incompleta. No se ha enviado ninguna foto.")
        XCTAssertFalse(app.staticTexts["externalAIInvocationCount"].exists)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        capture("consent-production-unavailable", app: app)
        app.buttons["cancelIdentificationPhoto"].tap()
        app.terminate()
        app.launchArguments.removeAll { $0 == "--storage-seed" }
        app.launchArguments += ["--storage-verify"]
        // --storage-verify compares both complete models and their JPEG bytes.
        app.launch(); assertCards(app)
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
    }

    func testExternalConsentReadErrorPreservesPhotoAndAllowsRetry() {
        let app = XCUIApplication()
        let id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--consent-fail-read", "--consent-spy", "--identification-photo-fixture"]
        app.launch(); prepareConsentPhoto(app)
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        let identify = app.buttons["identifyPhoto"]
        reveal(identify, in: app); identify.tap()
        let error = app.staticTexts["externalAIConsentError"]
        XCTAssertTrue(error.waitForExistence(timeout: 5)); reveal(error, in: app)
        XCTAssertTrue(error.label.contains("No se ha enviado ninguna foto."))
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        assertInvocations(0, app: app)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        capture("consent-read-error", app: app)
        reveal(identify, in: app); XCTAssertTrue(identify.isEnabled); identify.tap()
        XCTAssertTrue(error.waitForExistence(timeout: 5)); assertInvocations(0, app: app)
    }

}

final class IdentificationResultUITests: PlantCareAIUITestCase {
    func testIdentificationCandidatesReadOnlyResultReplacementAndStorageIsolation() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--consent-test-id", id, "--identification-photo-fixture", "--identification-candidates-fixture", "proposals"]
        app.launch(); assertCards(app)
        prepareConsentPhoto(app); requestConsent(app)
        let body = app.staticTexts["externalAIConsentBody"]
        XCTAssertTrue(body.label.contains("destino indicado")); XCTAssertFalse(body.label.contains("DevExpert"))
        XCTAssertFalse(body.label.contains("todavía no"))
        XCTAssertEqual(app.staticTexts["externalAIActualDestination"].label, "https://vision-one.invalid/v1/chat/completions")
        XCTAssertEqual(app.staticTexts["externalAIActualModel"].label, "vision-test-a")
        capture("identify-real-recipient-notice-fixture", app: app)
        app.buttons["cancelExternalAIConsent"].tap()
        XCTAssertTrue(app.navigationBars["Antes de usar IA externa"].waitForNonExistence(timeout: 5))
        assertInvocations(0, app: app)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.staticTexts["Costilla de Adán"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Otras posibilidades"].exists)
        XCTAssertTrue(app.staticTexts["Philodendron bipinnatifidum"].exists)
        XCTAssertFalse(app.staticTexts["Es una propuesta de IA, no una especie confirmada."].firstMatch.exists)
        XCTAssertTrue(app.buttons["confirmSpecies"].exists)
        XCTAssertFalse(app.buttons["confirmSpecies"].isEnabled)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["identificationUncertainty"].exists)
        capture("identify-proposals", app: app); assertInvocations(1, app: app)
        let invalid = app.buttons["fixture-photo-failure"]; reveal(invalid, in: app); invalid.tap()
        XCTAssertTrue(app.staticTexts["photoError"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Costilla de Adán"].exists)
        let b = app.buttons["fixture-photo-B"]; reveal(b, in: app); b.tap()
        expectation(for: NSPredicate(format: "value == %@", "80 × 120"), evaluatedWith: app.images["identificationPhotoPreview"])
        waitForExpectations(timeout: 10)
        XCTAssertFalse(app.staticTexts["Costilla de Adán"].exists); assertInvocations(1, app: app)
        app.buttons["cancelIdentificationPhoto"].tap()
        app.terminate(); app.launchArguments.removeAll { $0 == "--storage-seed" }; app.launchArguments += ["--storage-verify"]
        app.launch(); assertCards(app)
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
    }

    func testIdentificationInsufficientEvidence() { checkIdentificationResult("insufficient") }
    func testIdentificationWithoutAlternatives() { checkIdentificationResult("no-alternatives") }
    func testIdentificationExplicitErrorRetry() { checkIdentificationResult("error") }
    func testIdentificationLongNameRemainsReachable() { checkIdentificationResult("long") }

    private func checkIdentificationResult(_ mode: String) {
            let app = XCUIApplication(), id = isolatedID()
            app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture", "--identification-candidates-fixture", mode, "--care-sheet-fixture", "retained-error"]
            app.launch(); prepareConsentPhoto(app); requestConsent(app)
            let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
            if mode == "error" {
                let error = app.staticTexts["identificationError"]
                XCTAssertTrue(error.waitForExistence(timeout: 8)); reveal(error, in: app)
                XCTAssertTrue(error.label.contains("limitado")); XCTAssertFalse(app.staticTexts["No hay evidencia suficiente"].exists)
                XCTAssertFalse(app.buttons["confirmSpecies"].exists)
                XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
                capture("identify-error", app: app); assertInvocations(1, app: app)
                let identify = app.buttons["identifyPhoto"]; reveal(identify, in: app); identify.tap()
                XCTAssertTrue(app.staticTexts["Monstera deliciosa"].waitForExistence(timeout: 8))
                assertInvocations(2, app: app)
            } else if mode == "insufficient" {
                XCTAssertTrue(app.staticTexts["No hay evidencia suficiente"].waitForExistence(timeout: 8))
                XCTAssertFalse(app.staticTexts["Monstera deliciosa"].exists)
                XCTAssertTrue(app.staticTexts["Elige otra foto en la que se vean las hojas y el tallo."].exists)
                XCTAssertFalse(app.staticTexts["Es una propuesta de IA, no una especie confirmada."].firstMatch.exists)
                capture("identify-insufficient", app: app)
                XCTAssertTrue(app.buttons["confirmSpecies"].exists)
                XCTAssertFalse(app.buttons["confirmSpecies"].isEnabled)
                XCTAssertTrue(app.buttons["enterManualSpecies"].exists)
                XCTAssertFalse(app.buttons["speciesProposal-primary"].exists)
            } else if mode == "no-alternatives" {
                XCTAssertTrue(app.staticTexts["Monstera deliciosa"].waitForExistence(timeout: 8))
                XCTAssertTrue(app.staticTexts["Otras posibilidades"].exists)
                XCTAssertTrue(app.buttons["enterManualSpecies"].exists)
                XCTAssertFalse(app.buttons["speciesProposal-alternative-0"].exists)
                capture("identify-no-alternatives", app: app)
                // Manual/AI round trips belong to ManualSpeciesUITests. Here
                // verify the distinct one-proposal UI and its confirmation.
                let primary = app.buttons["speciesProposal-primary"]; revealInPhoto(primary, app: app); primary.tap()
                let confirm = app.buttons["confirmSpecies"]; reveal(confirm, in: app); confirm.tap()
                XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5)); assertNoCreationReview(app)
                XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Monstera deliciosa")
                XCTAssertFalse(app.staticTexts["careSheet-light"].exists)
                assertInvocations(1, app: app)
                let change = app.buttons["changeConfirmedSpecies"]; revealInPhoto(change, app: app)
                capture("repair-primary-change-safe-tap", app: app); change.tap()
                XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
                XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
                XCTAssertTrue(primary.isSelected)
            } else {
                XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
                XCTAssertFalse(app.staticTexts["identificationUncertainty"].exists)
                capture("identify-long-result", app: app)
                let primary = app.buttons["speciesProposal-primary"]
                let longName = String(String(repeating: "Costilla de Adán de hojas amplias ", count: 5).prefix(160))
                XCTAssertEqual(longName.count, 160); XCTAssertTrue(primary.label.contains(longName))
                revealAboveInPhoto(primary, app: app); primary.tap()
                let confirm = app.buttons["confirmSpecies"]; reveal(confirm, in: app)
                XCTAssertTrue(confirm.isEnabled); capture("confirm-long-selector-actions", app: app); confirm.tap()
                XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5)); assertNoCreationReview(app)
                XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Monstera deliciosa")
                let change = app.buttons["changeConfirmedSpecies"]; revealInPhoto(change, app: app)
                capture("confirm-long-summary", app: app); change.tap()
                XCTAssertFalse(app.staticTexts["identificationUncertainty"].exists)
                let identify = app.buttons["identifyPhoto"]; reveal(identify, in: app)
                XCTAssertTrue(identify.isHittable); XCTAssertTrue(identify.isEnabled)
                capture("identify-long-result-actions", app: app)
            }
            XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
            XCTAssertFalse(app.staticTexts["identificationUncertainty"].exists)
            app.terminate()
    }

    func testIdentificationWaitingCancellationCloseAndRelaunchWithoutDraft() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture", "--identification-candidates-fixture", "slow"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        let cancel = app.buttons["cancelIdentificationRequest"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5)); reveal(cancel, in: app)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        XCTAssertFalse(app.buttons["identifyPhoto"].isEnabled)
        XCTAssertFalse(app.buttons["confirmSpecies"].exists)
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        // The waiting state can already put the preview at the scroll view's top.
        // Reveal only if its actual geometry requires it; an unconditional downward
        // application swipe here becomes UISheet's native dismissal gesture.
        revealAboveInPhoto(app.images["identificationPhotoPreview"], app: app)
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].exists)
        XCTAssertTrue(app.images["identificationPhotoPreview"].isHittable)
        capture("identify-waiting", app: app); reveal(cancel, in: app); cancel.tap()
        XCTAssertTrue(cancel.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        XCTAssertFalse(app.buttons["confirmSpecies"].exists)
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        XCTAssertFalse(app.staticTexts["Monstera deliciosa"].exists)
        let identify = app.buttons["identifyPhoto"]; reveal(identify, in: app); identify.tap()
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        app.buttons["cancelIdentificationPhoto"].tap()
        app.terminate(); app.launch()
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["identificationPhotoPreview"].exists)
        XCTAssertFalse(app.staticTexts["Monstera deliciosa"].exists)
        assertInvocations(0, app: app)
    }

}

extension PlantCareAIUITestCase {
    fileprivate func openManual(_ app: XCUIApplication, changing: Bool = false) {
        let button = app.buttons[changing ? "changeConfirmedSpecies" : "enterManualSpecies"]
        revealInPhoto(button, app: app); button.tap()
        XCTAssertTrue(manualField(app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Introduce la especie"].exists)
        XCTAssertTrue(app.buttons["enterManualSpecies"].isSelected)
    }

    fileprivate func manualField(_ app: XCUIApplication) -> XCUIElement {
        app.textViews["manualSpeciesName"].exists ? app.textViews["manualSpeciesName"] : app.textFields["manualSpeciesName"]
    }

    fileprivate func selectAllAndDelete(_ field: XCUIElement, app: XCUIApplication, captureName: String, editorParagraphSelection: Bool = false) {
        if editorParagraphSelection {
            // Apple's native paragraph-selection gesture includes wrapped lines.
            // Require a selection menu; the caller's exact empty assertion after
            // one delete rejects partial selection (including multiple paragraphs).
            field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Copiar' OR label == 'Copy'")).firstMatch
            XCTAssertTrue(copy.waitForExistence(timeout: 3))
        } else {
            // Preserve the already-verified manual form's native menu interaction.
            field.press(forDuration: 1.2)
            let selectAll = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Seleccionar todo' OR label == 'Select All'")).firstMatch
            let next = app.buttons.matching(NSPredicate(format: "label == 'Adelante' OR label == 'Next'")).firstMatch
            for _ in 0..<3 where !selectAll.exists {
                guard next.waitForExistence(timeout: 2) else { break }
                next.tap()
            }
            XCTAssertTrue(selectAll.waitForExistence(timeout: 3))
            selectAll.tap()
        }
        capture(captureName, app: app)
        field.typeText(XCUIKeyboardKey.delete.rawValue)
    }

    fileprivate func typeManual(_ name: String, app: XCUIApplication) {
        let field = manualField(app)
        XCTAssertTrue(field.waitForExistence(timeout: 5)); revealInPhoto(field, app: app); field.tap()
        // Focusing can move the field under the keyboard accessory even when
        // isHittable remains true. Re-evaluate actual geometry before the native
        // long-press, using only content above the keyboard/Done overlay.
        revealFocusedManual(field, app: app)
        if !(field.value as? String ?? "").isEmpty && field.value as? String != field.placeholderValue {
            selectAllAndDelete(field, app: app, captureName: "manual-native-select-all")
            // A native empty TextField can expose its placeholder as value;
            // TextView generally exposes an empty string. Neither is residual text.
            let cleared = field.value as? String
            let isPlaceholder = field.elementType == .textField && field.placeholderValue != nil && cleared == field.placeholderValue
            XCTAssertTrue(cleared == "" || isPlaceholder,
                          "Expected empty field or its native placeholder, got: \(cleared ?? "<nil>")")
        }
        field.typeText(name)
        XCTAssertEqual(field.value as? String, name)
        capture("manual-keyboard", app: app)
        app.buttons["dismissManualSpeciesKeyboard"].tap()
    }

    private func revealFocusedManual(_ field: XCUIElement, app: XCUIApplication) {
        let bar = app.navigationBars["Foto de tu planta"]
        let done = app.buttons["dismissManualSpeciesKeyboard"]
        func bounds() -> (CGFloat, CGFloat) {
            var bottom = app.frame.maxY - 70
            if app.keyboards.firstMatch.exists { bottom = min(bottom, app.keyboards.firstMatch.frame.minY - 20) }
            if done.exists { bottom = min(bottom, done.frame.minY - 20) }
            return (bar.frame.maxY + 60, bottom)
        }
        for _ in 0..<8 {
            let (top, bottom) = bounds()
            XCTAssertGreaterThan(bottom - top, field.frame.height + 40)
            if field.isHittable && field.frame.minY > top && field.frame.maxY < bottom { break }
            let down = field.frame.minY <= top
            let originY = down ? top + 25 : bottom - 25
            let endY = down ? bottom - 25 : top + 25
            let origin = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.width * 0.95, dy: originY - app.frame.minY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.width * 0.95, dy: endY - app.frame.minY))
            origin.press(forDuration: 0.05, thenDragTo: end)
        }
        let (top, bottom) = bounds()
        XCTAssertTrue(field.isHittable)
        XCTAssertGreaterThan(field.frame.minY, top)
        XCTAssertLessThan(field.frame.maxY, bottom)
        capture("manual-unobscured-native-target", app: app)
    }

    fileprivate func confirmManual(_ app: XCUIApplication) {
        let button = app.buttons["confirmSpecies"]
        revealInPhoto(button, app: app); XCTAssertTrue(button.isEnabled); button.tap()
        XCTAssertTrue(manualField(app).waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["confirmedManualName"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5)); assertNoCreationReview(app)
    }

}

final class ManualSpeciesUITests: PlantCareAIUITestCase {
    func testManualSpeciesAfterZeroCandidatesAndCancelEdit() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id,
                               "--identification-candidates-fixture", "insufficient", "--identification-photo-fixture", "--care-sheet-fixture", "retained-error", "-AppleLanguages", "(es)"]
        app.launch(); prepareConsentPhoto(app)
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.staticTexts["No hay evidencia suficiente"].waitForExistence(timeout: 8))
        openManual(app)
        XCTAssertFalse(app.buttons["confirmSpecies"].isEnabled)
        capture("manual-empty", app: app)
        typeManual("   ", app: app); XCTAssertFalse(app.buttons["confirmSpecies"].isEnabled)
        let manual = app.buttons["enterManualSpecies"]
        revealInPhoto(manual, app: app); manual.tap()
        XCTAssertFalse(manual.isSelected); XCTAssertFalse(manualField(app).exists)
        XCTAssertTrue(app.buttons["chooseGalleryPhoto"].isEnabled)
        XCTAssertTrue(app.buttons["takePlantPhoto"].isEnabled)
        XCTAssertTrue(app.buttons["identifyPhoto"].isEnabled)
        openManual(app)
        let emptyValue = manualField(app).value as? String ?? ""
        XCTAssertTrue(emptyValue.isEmpty || emptyValue == manualField(app).placeholderValue)
        app.buttons["cancelManualSpecies"].tap(); openManual(app)
        XCTAssertFalse(app.buttons["confirmSpecies"].isEnabled)
        typeManual("  Ficus lyrata  ", app: app); capture("manual-filled", app: app); confirmManual(app)
        XCTAssertEqual(app.staticTexts["confirmedManualName"].label, "Ficus lyrata")
        XCTAssertTrue(app.staticTexts["careSheetError"].exists); assertNoCreationReview(app)
        XCTAssertFalse(app.staticTexts["confirmedScientificName"].exists)
        XCTAssertFalse(app.buttons["returnToAIProposals"].exists)
        assertInvocations(1, app: app); capture("manual-summary", app: app)
        openManual(app, changing: true)
        XCTAssertEqual(manualField(app).value as? String, "Ficus lyrata")
        typeManual(" cancelado", app: app); app.buttons["cancelManualSpecies"].tap()
        XCTAssertEqual(app.staticTexts["confirmedManualName"].label, "Ficus lyrata")
        openManual(app, changing: true)
        XCTAssertEqual(manualField(app).value as? String, "Ficus lyrata")
        let cancelEdit = app.buttons["cancelManualSpecies"]
        revealInPhoto(cancelEdit, app: app); cancelEdit.tap()
        XCTAssertTrue(manualField(app).waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].exists)
        XCTAssertEqual(app.staticTexts["confirmedManualName"].label, "Ficus lyrata")
        openManual(app, changing: true); typeManual("Ficus nuevo", app: app); confirmManual(app)
        XCTAssertEqual(app.staticTexts["confirmedManualName"].label, "Ficus nuevo")
        assertInvocations(1, app: app)
    }

    func testManualSpeciesFromProposalsAndReturn() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture",
                               "--identification-candidates-fixture", "proposals", "--care-sheet-fixture", "retained-error", "-AppleLanguages", "(es)"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        let alternative = app.buttons["speciesProposal-alternative-0"]
        XCTAssertTrue(alternative.waitForExistence(timeout: 8)); revealInPhoto(alternative, app: app); alternative.tap()
        XCTAssertFalse(app.staticTexts["Es una propuesta de IA, no una especie confirmada."].firstMatch.exists)
        openManual(app); typeManual("Sin confirmar", app: app)
        XCTAssertFalse(alternative.isSelected)
        XCTAssertTrue(app.buttons["enterManualSpecies"].isSelected)
        XCTAssertEqual(app.buttons.matching(identifier: "confirmSpecies").count, 1)
        revealInPhoto(alternative, app: app); alternative.tap()
        XCTAssertFalse(manualField(app).exists); XCTAssertFalse(app.buttons["enterManualSpecies"].isSelected)
        XCTAssertTrue(alternative.isSelected); XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        revealInPhoto(alternative, app: app); alternative.tap()
        XCTAssertFalse(alternative.isSelected); XCTAssertFalse(app.buttons["confirmSpecies"].isEnabled)
        alternative.tap(); XCTAssertTrue(alternative.isSelected)
        assertInvocations(1, app: app); capture("inline-ai-exclusive", app: app)
        openManual(app)
        let fieldValue = manualField(app).value as? String ?? ""
        XCTAssertTrue(fieldValue.isEmpty || fieldValue == manualField(app).placeholderValue)
        typeManual("Cancelado", app: app); app.buttons["cancelManualSpecies"].tap()
        XCTAssertTrue(alternative.isSelected); XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        let confirm = app.buttons["confirmSpecies"]; revealInPhoto(confirm, app: app); confirm.tap()
        XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5)); assertNoCreationReview(app)
        let previous = app.staticTexts["confirmedScientificName"].label
        let change = app.buttons["changeConfirmedSpecies"]; revealInPhoto(change, app: app); change.tap()
        openManual(app); typeManual("Cancelado", app: app); app.buttons["cancelManualSpecies"].tap()
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, previous)
        revealInPhoto(change, app: app); change.tap()
        openManual(app); typeManual("Potus", app: app); confirmManual(app)
        XCTAssertFalse(app.staticTexts["confirmedScientificName"].exists); assertInvocations(1, app: app)
        let back = app.buttons["returnToAIProposals"]; revealInPhoto(back, app: app); back.tap()
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists); XCTAssertTrue(alternative.isSelected)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        XCTAssertTrue(confirm.isEnabled); capture("manual-return-to-ai", app: app)
        revealInPhoto(confirm, app: app); confirm.tap()
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, previous); assertInvocations(1, app: app)
    }

    func testManualSpeciesInvalidationCloseAndStorageIsolation() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--consent-test-id", id,
                               "--identification-candidates-fixture", "insufficient", "--identification-photo-fixture", "--care-sheet-fixture", "retained-error", "-AppleLanguages", "(es)"]
        app.launch(); assertCards(app); prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.staticTexts["No hay evidencia suficiente"].waitForExistence(timeout: 8))
        openManual(app)
        let long = String(repeating: "Planta conocida ", count: 20) + "fin"
        typeManual(long, app: app); capture("manual-long-editor", app: app); confirmManual(app)
        XCTAssertEqual(app.staticTexts["confirmedManualName"].label, long)
        let failure = app.buttons["fixture-photo-failure"]; revealInPhoto(failure, app: app); failure.tap()
        XCTAssertTrue(app.staticTexts["photoError"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.staticTexts["confirmedManualName"].label, long)
        let b = app.buttons["fixture-photo-B"]; revealInPhoto(b, app: app); b.tap()
        expectation(for: NSPredicate(format: "value == %@", "80 × 120"), evaluatedWith: app.images["identificationPhotoPreview"])
        waitForExpectations(timeout: 10); XCTAssertFalse(app.staticTexts["confirmedManualName"].exists)
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        capture("manual-new-photo-cleared", app: app)
        let identify = app.buttons["identifyPhoto"]; revealInPhoto(identify, app: app); identify.tap()
        XCTAssertTrue(app.staticTexts["No hay evidencia suficiente"].waitForExistence(timeout: 8))
        openManual(app); typeManual("Potus", app: app); confirmManual(app)
        revealInPhoto(identify, app: app); identify.tap()
        XCTAssertFalse(app.staticTexts["confirmedManualName"].exists)
        XCTAssertTrue(app.staticTexts["No hay evidencia suficiente"].waitForExistence(timeout: 8))
        assertInvocations(3, app: app)
        openManual(app); typeManual("Potus", app: app); confirmManual(app)
        let bar = app.navigationBars["Foto de tu planta"]
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.9)))
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["confirmedManualName"].exists); XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
        app.buttons["cancelIdentificationPhoto"].tap()
        app.terminate(); app.launchArguments.removeAll { $0 == "--storage-seed" }; app.launchArguments += ["--storage-verify"]
        app.launch(); assertCards(app)
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["confirmedManualName"].exists)
    }

    func testManualUnconfirmedDraftDiscardedAfterInsufficientEvidence() { checkUnconfirmedClose("insufficient") }
    func testManualUnconfirmedDraftDiscardedAfterErrorRecovery() { checkUnconfirmedClose("error") }

    private func checkUnconfirmedClose(_ mode: String) {
            let app = XCUIApplication(), id = isolatedID()
            app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture",
                                   "--identification-candidates-fixture", mode, "--care-sheet-fixture", "retained-error", "-AppleLanguages", "(es)"]
            app.launch(); prepareConsentPhoto(app); requestConsent(app)
            let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
            let result = app.staticTexts[mode == "error" ? "identificationError" : "identificationResultHeading"]
            XCTAssertTrue(result.waitForExistence(timeout: 8))
            if mode == "error" {
                XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
                let identify = app.buttons["identifyPhoto"]; revealInPhoto(identify, app: app); identify.tap()
                XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
            }
            openManual(app); typeManual("Potus", app: app); confirmManual(app)
            XCTAssertEqual(app.buttons["returnToAIProposals"].exists, mode == "error")
            assertInvocations(mode == "error" ? 2 : 1, app: app)
            openManual(app, changing: true); typeManual("Descartar gesto", app: app)
            let cancelEdit = app.buttons["cancelManualSpecies"]
            revealInPhoto(cancelEdit, app: app); cancelEdit.tap()
            XCTAssertTrue(manualField(app).waitForNonExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["confirmedManualName"].label, "Potus")
            app.buttons["cancelIdentificationPhoto"].tap()
            app.buttons["addPlantHeader"].tap()
            XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts["confirmedManualName"].exists)
            app.buttons["cancelIdentificationPhoto"].tap()
            prepareConsentPhoto(app)
            XCTAssertFalse(app.buttons["enterManualSpecies"].exists)
            let identify = app.buttons["identifyPhoto"]; revealInPhoto(identify, app: app); identify.tap()
            if mode == "error" {
                // The process-scoped fixture fails only its first invocation, already checked above.
                XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
                XCTAssertFalse(app.staticTexts["identificationError"].exists)
            }
            XCTAssertTrue(app.buttons["enterManualSpecies"].waitForExistence(timeout: 8))
            assertInvocations(mode == "error" ? 3 : 2, app: app)
            openManual(app); typeManual("Sin confirmar", app: app)
            app.terminate(); app.launch()
            app.buttons["addPlantHeader"].tap()
            XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
            XCTAssertFalse(app.navigationBars["Introduce la especie"].exists)
            XCTAssertFalse(app.staticTexts["confirmedManualName"].exists)
            app.terminate()
    }

}

final class ConfirmSpeciesUITests: PlantCareAIUITestCase {
    func testConfirmSpeciesAlternativeAndDraftInvalidation() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--consent-test-id", id,
                               "--identification-photo-fixture", "--identification-candidates-fixture", "proposals", "--care-sheet-fixture", "retained-error"]
        app.launch(); assertCards(app)
        prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        let primary = app.buttons["speciesProposal-primary"], alternative = app.buttons["speciesProposal-alternative-0"]
        XCTAssertTrue(primary.waitForExistence(timeout: 8))
        let confirm = app.buttons["confirmSpecies"]
        XCTAssertFalse(confirm.isEnabled); XCTAssertFalse(primary.isSelected); XCTAssertFalse(alternative.isSelected)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        revealAboveInPhoto(app.images["identificationPhotoPreview"], app: app)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        capture("confirm-unselected", app: app)
        reveal(confirm, in: app); XCTAssertFalse(confirm.isEnabled)
        capture("confirm-unselected-actions", app: app)
        revealAboveInPhoto(primary, app: app)
        reveal(primary, in: app); primary.tap()
        XCTAssertTrue(primary.isSelected); XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        reveal(alternative, in: app); alternative.tap()
        XCTAssertTrue(alternative.isSelected); XCTAssertFalse(primary.isSelected)
        capture("confirm-alternative-selected", app: app)
        reveal(confirm, in: app); XCTAssertTrue(confirm.isEnabled); confirm.tap()
        XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5)); assertNoCreationReview(app)
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Philodendron bipinnatifidum")
        XCTAssertTrue(app.staticTexts["careSheetError"].label.contains("conectar"))
        XCTAssertNotEqual(app.staticTexts["confirmedScientificName"].label, "Monstera deliciosa")
        XCTAssertFalse(primary.exists) // The collection behind the sheet legitimately has this species.
        XCTAssertFalse(app.staticTexts["confirmedDraftNotice"].exists)
        XCTAssertFalse(app.staticTexts["careSheet-light"].exists)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.buttons["Guardar"].exists); XCTAssertFalse(app.buttons["Generar cuidados"].exists)
        assertInvocations(1, app: app)
        revealAboveInPhoto(app.images["identificationPhotoPreview"], app: app)
        capture("confirm-alternative-summary", app: app)
        let change = app.buttons["changeConfirmedSpecies"]; revealInPhoto(change, app: app); change.tap()
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists); XCTAssertTrue(alternative.isSelected)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        revealAboveInPhoto(primary, app: app)
        reveal(primary, in: app); primary.tap()
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        reveal(confirm, in: app); confirm.tap()
        XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Monstera deliciosa")
        let failure = app.buttons["fixture-photo-failure"]; reveal(failure, in: app); failure.tap()
        XCTAssertTrue(app.staticTexts["photoError"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Monstera deliciosa")
        XCTAssertEqual(app.images["identificationPhotoPreview"].value as? String, "120 × 80")
        assertInvocations(1, app: app)
        let b = app.buttons["fixture-photo-B"]; reveal(b, in: app); b.tap()
        expectation(for: NSPredicate(format: "value == %@", "80 × 120"), evaluatedWith: app.images["identificationPhotoPreview"])
        waitForExpectations(timeout: 10)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        XCTAssertFalse(primary.exists); XCTAssertFalse(confirm.exists)
        XCTAssertFalse(app.buttons["enterManualSpecies"].exists); assertInvocations(1, app: app)
        revealAboveInPhoto(app.images["identificationPhotoPreview"], app: app)
        capture("confirm-new-photo-no-identity", app: app)
        let identify = app.buttons["identifyPhoto"]; reveal(identify, in: app); identify.tap()
        XCTAssertTrue(primary.waitForExistence(timeout: 8)); XCTAssertFalse(primary.isSelected); XCTAssertFalse(confirm.isEnabled)
        reveal(alternative, in: app); alternative.tap(); reveal(confirm, in: app); confirm.tap()
        assertInvocations(2, app: app)
        // Starting a new request immediately discards the identity; equal names are not selected again.
        reveal(identify, in: app); identify.tap()
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        XCTAssertTrue(primary.waitForExistence(timeout: 8)); XCTAssertFalse(primary.isSelected); XCTAssertFalse(confirm.isEnabled)
        reveal(alternative, in: app); alternative.tap(); reveal(confirm, in: app); confirm.tap()
        assertInvocations(3, app: app)
        let bar = app.navigationBars["Foto de tu planta"]
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.9)))
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["identificationPhotoPreview"].exists); XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        XCTAssertFalse(confirm.exists); app.buttons["cancelIdentificationPhoto"].tap()
        app.terminate(); app.launchArguments.removeAll { $0 == "--storage-seed" }; app.launchArguments += ["--storage-verify"]
        app.launch(); assertCards(app)
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists); XCTAssertFalse(confirm.exists)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
    }

}

final class CollectionLayoutUITests: PlantCareAIUITestCase {
    func testCollectionFixedHeaderWithPlantsAndDetailAfterScroll() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "-AppleLanguages", "(es)"]
        app.launch()
        let first = app.buttons["plantCard-\(plantID(1))"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        let title = app.staticTexts["collectionTitle"], add = app.buttons["addPlantHeader"]
        let titleBefore = title.frame, addBefore = add.frame, cardBefore = first.frame
        capture("repair-list-before-scroll", app: app)
        app.scrollViews["collectionViewport"].swipeUp()
        XCTAssertGreaterThan(abs(first.frame.minY - cardBefore.minY), 40)
        XCTAssertEqual(title.frame.midY, titleBefore.midY, accuracy: 3)
        XCTAssertEqual(add.frame.midY, addBefore.midY, accuracy: 3)
        XCTAssertTrue(add.isHittable)
        capture("repair-list-after-scroll", app: app)
        let second = app.buttons["plantCard-\(plantID(2))"]
        reveal(second, in: app); second.tap()
        XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(2))"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(2))"].label.hasPrefix("Fixture 2"))
        XCTAssertFalse(app.staticTexts["selectedPlant-\(plantID(1))"].exists)
        back(app)
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
    }

    func testEmptyCollectionCenteredBelowFixedHeaderAndAddWorks() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["collectionTitle"].label, "Mis plantas")
        XCTAssertEqual(app.staticTexts["emptyCollectionTitle"].label, "Todavía no tienes plantas")
        XCTAssertTrue(app.staticTexts["Guarda aquí tus plantas para tener sus cuidados a mano."].exists)
        XCTAssertEqual(app.buttons["addFirstPlant"].label, "Añadir mi primera planta")
        XCTAssertTrue(app.buttons["addFirstPlant"].isEnabled)
        XCTAssertTrue(app.buttons["addPlantHeader"].isEnabled)
        XCTAssertFalse(app.staticTexts["Actividad"].exists)
        XCTAssertFalse(app.staticTexts["Disponible cuando puedas elegir una foto."].exists)
        XCTAssertFalse(app.staticTexts["Preparando tu espacio para cuidar plantas."].exists)
        XCTAssertTrue(app.buttons["addPlantHeader"].label.contains("Añadir"))
        let title = app.staticTexts["collectionTitle"], add = app.buttons["addPlantHeader"]
        let card = app.descendants(matching: .any)["emptyCollectionCard"].firstMatch
        let viewport = app.scrollViews["collectionViewport"]
        XCTAssertTrue(card.exists); XCTAssertTrue(viewport.exists)
        XCTAssertGreaterThan(viewport.frame.minY, title.frame.maxY)
        XCTAssertGreaterThan(card.frame.minY, viewport.frame.minY)
        XCTAssertEqual(card.frame.midX, viewport.frame.midX, accuracy: 12)
        // ScrollView includes the bottom safe-area inset on some iOS versions.
        // 28 pt tolerates that, but rejects a top-aligned empty card.
        XCTAssertEqual(card.frame.midY, viewport.frame.midY, accuracy: 28)
        let titleBefore = title.frame, addBefore = add.frame
        viewport.swipeUp()
        XCTAssertEqual(title.frame.midY, titleBefore.midY, accuracy: 3)
        XCTAssertEqual(add.frame.midY, addBefore.midY, accuracy: 3)
        XCTAssertTrue(add.isHittable)
        capture("repair-empty-centered-fixed-header", app: app)
        app.buttons["addFirstPlant"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
        app.buttons["cancelIdentificationPhoto"].tap()
        add.tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
    }

}

extension PlantCareAIUITestCase {
    fileprivate func assertRetryLayout(after action: XCUIElement, app: XCUIApplication, manualVisible: Bool = true) {
        let gallery = app.buttons["chooseGalleryPhoto"], camera = app.buttons["takePlantPhoto"], identify = app.buttons["identifyPhoto"]
        // Use the viewport's outer gutter: the 95% path can intersect the manual
        // option's expanded touch target while scrolling the taller selector.
        // A layout inspection must not change the selected option.
        let manual = app.buttons["enterManualSpecies"]
        func assertManualState() {
            XCTAssertEqual(manual.exists, manualVisible)
            if manualVisible { XCTAssertFalse(manual.isSelected) }
        }
        assertManualState()
        revealInPhoto(gallery, app: app, gutterX: 0.99)
        assertManualState()
        let separator = app.staticTexts["identificationRetrySeparator"]
        let heading = app.staticTexts["identificationRetryHeading"]
        XCTAssertTrue(separator.exists); XCTAssertTrue(heading.exists)
        XCTAssertGreaterThan(separator.frame.minY - action.frame.maxY, 12)
        XCTAssertGreaterThan(heading.frame.minY, separator.frame.maxY)
        XCTAssertGreaterThan(gallery.frame.minY, heading.frame.maxY)
        for button in [camera, identify] {
            XCTAssertEqual(button.frame.width, gallery.frame.width, accuracy: 3)
            XCTAssertEqual(button.frame.height, gallery.frame.height, accuracy: 3)
        }
        XCTAssertGreaterThanOrEqual(gallery.frame.height, 44)
        XCTAssertGreaterThan(camera.frame.minY, gallery.frame.maxY)
        XCTAssertGreaterThan(identify.frame.minY, camera.frame.maxY)
        revealInPhoto(identify, app: app, gutterX: 0.99)
        assertManualState()
        XCTAssertTrue(identify.isEnabled)
    }

}

final class IdentificationLayoutUITests: PlantCareAIUITestCase {
    func testMaximumAlternativesLastSelectionAndSeparatedEqualActions() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id,
                               "--identification-photo-fixture", "--identification-candidates-fixture", "max-alternatives", "--care-sheet-fixture", "retained-error"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        let primary = app.buttons["speciesProposal-primary"], last = app.buttons["speciesProposal-alternative-2"]
        XCTAssertTrue(primary.waitForExistence(timeout: 8))
        XCTAssertTrue(last.exists); XCTAssertFalse(app.buttons["speciesProposal-alternative-3"].exists)
        let confirm = app.buttons["confirmSpecies"]
        XCTAssertFalse(confirm.isEnabled)
        for proposal in [primary] + (0...2).map({ app.buttons["speciesProposal-alternative-\($0)"] }) {
            XCTAssertFalse(proposal.isSelected)
        }
        assertRetryLayout(after: confirm, app: app)
        capture("repair-max-alternatives-separated-actions", app: app)
        revealInPhoto(last, app: app); last.tap()
        XCTAssertTrue(last.label.contains("Alternativa de prueba 3"))
        XCTAssertTrue(last.isSelected); XCTAssertFalse(primary.isSelected)
        XCTAssertFalse(app.buttons["speciesProposal-alternative-0"].isSelected)
        XCTAssertFalse(app.buttons["speciesProposal-alternative-1"].isSelected)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        capture("repair-max-last-selected", app: app)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        revealInPhoto(confirm, app: app); XCTAssertTrue(confirm.isEnabled); confirm.tap()
        XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5)); assertNoCreationReview(app)
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Species fixture 3")
        assertInvocations(1, app: app)
        let change = app.buttons["changeConfirmedSpecies"]
        assertRetryLayout(after: change, app: app, manualVisible: false)
        revealInPhoto(change, app: app)
        capture("repair-max-confirmed-separated-actions", app: app); change.tap()
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists); XCTAssertTrue(last.isSelected)
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        revealInPhoto(confirm, app: app); confirm.tap(); assertInvocations(1, app: app)
    }

    func testGenericDestinationConsentShowsSnapshotAndRenewsAfterDestinationModelChange() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture", "--identification-candidates-fixture", "proposals"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        let destination = app.staticTexts["externalAIActualDestination"]
        reveal(destination, in: app)
        XCTAssertEqual(destination.label, "https://vision-one.invalid/v1/chat/completions")
        XCTAssertEqual(app.staticTexts["externalAIActualModel"].label, "vision-test-a")
        XCTAssertTrue(app.staticTexts["externalAIUnknownOperator"].label.contains("no verifica quién opera"))
        capture("generic-consent-first-destination", app: app)
        app.buttons["cancelExternalAIConsent"].tap(); assertInvocations(0, app: app)
        requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        assertInvocations(1, app: app)
        app.terminate()
        app.launchArguments += ["--identification-second-destination"]
        app.launch(); prepareConsentPhoto(app); assertInvocations(0, app: app)
        requestConsent(app) // Same preference suite cannot inherit the other destination/model.
        reveal(destination, in: app)
        XCTAssertEqual(destination.label, "https://vision-two.invalid/api/chat/completions")
        XCTAssertEqual(app.staticTexts["externalAIActualModel"].label, "vision-test-b")
        capture("generic-consent-renewed-destination", app: app)
        assertInvocations(0, app: app)
        reveal(accept, in: app); accept.tap(); assertInvocations(1, app: app)
        app.buttons["cancelIdentificationPhoto"].tap()
        prepareConsentPhoto(app)
        let identify = app.buttons["identifyPhoto"]; reveal(identify, in: app); identify.tap()
        assertInvocations(2, app: app)
        XCTAssertFalse(app.navigationBars["Antes de usar IA externa"].exists)
    }

}

extension PlantCareAIUITestCase {
    fileprivate func prepareCare(_ app: XCUIApplication, mode: String = "success", renewConsent: Bool = false, seed: Bool = false) {
        let id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture",
                               "--identification-candidates-fixture", "proposals", "--care-sheet-fixture", mode, "-AppleLanguages", "(es)"]
        if renewConsent { app.launchArguments += ["--care-sheet-renew-consent"] }
        if seed { app.launchArguments += ["--storage-seed"] }
        app.launch()
        if seed { assertCards(app) }
        prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
    }

    fileprivate func assertCareCount(_ count: Int, app: XCUIApplication) {
        let counter = app.staticTexts["careSheetInvocationCount"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label == %@", "Care invocations: \(count)"), evaluatedWith: counter)
        waitForExpectations(timeout: 8)
    }

    fileprivate func confirmCareAlternative(_ app: XCUIApplication) {
        let option = app.buttons["speciesProposal-alternative-0"]
        revealInPhoto(option, app: app); option.tap()
        assertCareCount(0, app: app)
        let confirm = app.buttons["confirmSpecies"]; revealInPhoto(confirm, app: app); confirm.tap()
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.buttons["Generar cuidados"].exists)
    }

    fileprivate func assertCareFields(_ name: String, app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForNonExistence(timeout: 10))
        assertNoCreationReview(app)
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "plantCard-", name)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 8)); reveal(card, in: app)
        let id = String(card.identifier.dropFirst("plantCard-".count))
        card.tap()
        XCTAssertTrue(app.staticTexts["detailSpecies-" + id].waitForExistence(timeout: 8))
        for field in ["light", "watering", "humidity", "temperature", "substrate", "fertilizer"] {
            let text = app.staticTexts["detailCare-" + field + "-" + id]
            XCTAssertTrue(text.exists); XCTAssertTrue(text.label.contains(name))
            reveal(text, in: app); XCTAssertTrue(text.isHittable)
        }
        XCTAssertTrue(app.staticTexts["detailDisclaimer"].exists)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.staticTexts["confirmedDraftNotice"].exists)
        XCTAssertFalse(app.buttons["Guardar"].exists); XCTAssertFalse(app.buttons["Añadir planta"].exists)
        capture("care-six-fields-abonado", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

}

final class CareSheetUITests: PlantCareAIUITestCase {
    func testCareSheetDirectAlternativeAndManualSave() {
        let app = XCUIApplication(); prepareCare(app)
        confirmCareAlternative(app); assertCareFields("Philodendron bipinnatifidum", app: app)
        assertCareCount(1, app: app); assertInvocations(1, app: app)
        prepareConsentPhoto(app)
        let identify = app.buttons["identifyPhoto"]; revealInPhoto(identify, app: app); identify.tap()
        XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["careSheet-light"].exists)
        openManual(app); typeManual("  Ficus lyrata  ", app: app)
        let confirm = app.buttons["confirmSpecies"]; revealInPhoto(confirm, app: app); confirm.tap()
        assertCareFields("Ficus lyrata", app: app); assertCareCount(1, app: app); assertInvocations(2, app: app)
        capture("care-manual-review", app: app)
    }

    func testCareSheetNetworkFailureAndExplicitRetry() { checkCareRetry("error") }
    func testCareSheetIncompleteResponseAndExplicitRetry() { checkCareRetry("incomplete") }
    func testCareSheetRenewedConsentCancellationAndRetry() { checkCareRetry("renew") }

    private func checkCareRetry(_ mode: String) {
            let app = XCUIApplication(); prepareCare(app, mode: mode, renewConsent: mode == "renew")
            confirmCareAlternative(app)
            if mode == "renew" {
                XCTAssertTrue(app.navigationBars["Antes de usar IA externa"].waitForExistence(timeout: 8))
                let body = app.staticTexts["externalAIConsentBody"]
                XCTAssertTrue(body.label.contains("no volvemos a enviar la foto"))
                app.buttons["cancelExternalAIConsent"].tap()
                XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5))
                assertCareCount(0, app: app)
            } else {
                let error = app.staticTexts["careSheetError"]
                XCTAssertTrue(error.waitForExistence(timeout: 8))
                XCTAssertTrue(error.label.contains(mode == "error" ? "conectar" : "completa"))
                assertCareCount(1, app: app)
            }
            XCTAssertFalse(app.staticTexts["careSheet-light"].exists); XCTAssertFalse(app.buttons["Guardar"].exists)
            XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Philodendron bipinnatifidum")
            revealAboveInPhoto(app.staticTexts["careSheetError"], app: app)
            capture("care-\(mode)-error", app: app)
            let retry = app.buttons["retryCareSheet"]; revealInPhoto(retry, app: app); retry.tap()
            if mode == "renew" {
                XCTAssertTrue(app.navigationBars["Antes de usar IA externa"].waitForExistence(timeout: 5))
                let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
            }
            assertCareFields("Philodendron bipinnatifidum", app: app)
            assertCareCount(mode == "renew" ? 1 : 2, app: app)
            assertInvocations(1, app: app)
            app.terminate()
    }

    func testCareSheetCancellationCloseAndStorageIsolation() {
        let app = XCUIApplication(); prepareCare(app, mode: "waiting", seed: true)
        confirmCareAlternative(app)
        let cancel = app.buttons["cancelCareSheetRequest"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        // Confirmation replaces the tall proposal with a short loading status,
        // leaving Cancelar under the navigation overlay. The 0.95 gutter lands
        // at the padded content's trailing edge (382 pt on a 402 pt viewport)
        // and the recorded drags there did not reveal the target. Start inside the content,
        // not that edge; retain the shared helper's bounds and geometry checks.
        revealInPhoto(cancel, app: app, gutterX: 0.85)
        XCTAssertTrue(app.staticTexts["careSheetLoading"].exists || app.activityIndicators.count > 0)
        XCTAssertFalse(app.buttons["identifyPhoto"].isEnabled); XCTAssertFalse(app.buttons["changeConfirmedSpecies"].isEnabled)
        capture("care-waiting", app: app); cancel.tap()
        XCTAssertTrue(app.staticTexts["careSheetError"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["careSheet-light"].exists); assertCareCount(1, app: app)
        assertNoCreationReview(app)
        XCTAssertEqual(app.staticTexts["confirmedScientificName"].label, "Philodendron bipinnatifidum")
        let retry = app.buttons["retryCareSheet"]; revealInPhoto(retry, app: app); retry.tap()
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        app.buttons["cancelIdentificationPhoto"].tap()
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["careSheet-light"].exists); XCTAssertFalse(app.staticTexts["confirmedScientificName"].exists)
        app.buttons["cancelIdentificationPhoto"].tap()
        app.terminate(); app.launchArguments.removeAll { $0 == "--storage-seed" }; app.launchArguments += ["--storage-verify"]
        app.launch(); assertCards(app)
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
    }

    func testCareSheetThousandCharacterTextScrollsAndPersists() {
        let app = XCUIApplication(); prepareCare(app, mode: "long")
        confirmCareAlternative(app)
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForNonExistence(timeout: 10)); assertNoCreationReview(app)
        let card = createdCards(app).firstMatch; XCTAssertTrue(card.waitForExistence(timeout: 8)); reveal(card, in: app)
        let id = String(card.identifier.dropFirst("plantCard-".count))
        card.tap()
        let fertilizer = app.staticTexts["detailCare-fertilizer-" + id]
        XCTAssertTrue(fertilizer.waitForExistence(timeout: 8))
        let expectedLong = String(("Abonado para Philodendron bipinnatifidum. Comprueba las condiciones de tu planta." + String(repeating: " Consejo orientativo según el sustrato.", count: 30)).prefix(999)) + "."
        XCTAssertEqual(expectedLong.count, 1000); XCTAssertTrue(fertilizer.label.contains(expectedLong))
        reveal(fertilizer, in: app); XCTAssertTrue(fertilizer.isHittable)
        capture("care-long-abonado", app: app)
        app.navigationBars.buttons.element(boundBy: 0).tap(); assertCareCount(1, app: app)
        // Photo replacement and a second manual save have dedicated scenarios.
        // This test owns the exact 1000-character field, scrolling and relaunch.
        XCTAssertEqual(createdCards(app).count, 1)
        app.terminate(); app.launch(); XCTAssertTrue(app.buttons["plantCard-" + id].waitForExistence(timeout: 8))
        reveal(app.buttons["plantCard-" + id], in: app); app.buttons["plantCard-" + id].tap()
        XCTAssertTrue(fertilizer.waitForExistence(timeout: 8)); XCTAssertTrue(fertilizer.label.contains(expectedLong))
    }

}

extension PlantCareAIUITestCase {
    fileprivate func createdCards(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "plantCard-"))
    }

    fileprivate func assertNoCreationReview(_ app: XCUIApplication) {
        XCTAssertFalse(app.staticTexts["careSheetOrientation"].exists)
        XCTAssertFalse(app.staticTexts["careSheet-light"].exists)
        XCTAssertFalse(app.staticTexts["confirmedSpeciesHeading"].exists)
        XCTAssertFalse(app.buttons["Guardar"].exists)
        XCTAssertFalse(app.textFields["plantNameField"].exists)
    }

}

final class SavePlantUITests: PlantCareAIUITestCase {
    func testSavePlantAutomaticAIAndManualSameSpeciesRelaunch() {
        let app = XCUIApplication(); prepareCare(app)
        let primary = app.buttons["speciesProposal-primary"]
        revealInPhoto(primary, app: app); primary.tap()
        assertCareCount(0, app: app); assertNoCreationReview(app)
        let confirm = app.buttons["confirmSpecies"]; revealInPhoto(confirm, app: app); confirm.tap()
        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(createdCards(app).count, 1)
        let firstID = createdCards(app).element(boundBy: 0).identifier
        capture("save-first-collection", app: app)
        prepareConsentPhoto(app)
        let replacement = app.buttons["fixture-photo-B"]; revealInPhoto(replacement, app: app); replacement.tap()
        expectation(for: NSPredicate(format: "value == %@", "80 × 120"), evaluatedWith: app.images["identificationPhotoPreview"])
        waitForExpectations(timeout: 10)
        let identify = app.buttons["identifyPhoto"]; revealInPhoto(identify, app: app); identify.tap()
        XCTAssertTrue(primary.waitForExistence(timeout: 8))
        openManual(app); typeManual("Monstera deliciosa", app: app)
        revealInPhoto(confirm, app: app); confirm.tap()
        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(createdCards(app).count, 2)
        let ids = (0..<2).map { createdCards(app).element(boundBy: $0).identifier }
        XCTAssertTrue(ids.contains(firstID)); XCTAssertEqual(Set(ids).count, 2)
        capture("save-two-collection", app: app)
        app.terminate(); app.launch()
        XCTAssertTrue(createdCards(app).firstMatch.waitForExistence(timeout: 8))
        XCTAssertEqual(Set((0..<2).map { createdCards(app).element(boundBy: $0).identifier }), Set(ids))
        for id in ids {
            let card = app.buttons[id]; reveal(card, in: app); card.tap()
            let uuid = String(id.dropFirst("plantCard-".count))
            XCTAssertTrue(app.staticTexts["detailSpecies-" + uuid].waitForExistence(timeout: 8))
            XCTAssertTrue(app.staticTexts["detailSpecies-" + uuid].label.contains("Monstera deliciosa"))
            XCTAssertFalse(app.staticTexts["detailLocation-" + uuid].exists)
            for field in ["light", "watering", "humidity", "temperature", "substrate", "fertilizer"] {
                let text = app.staticTexts["detailCare-" + field + "-" + uuid]
                reveal(text, in: app); XCTAssertTrue(text.label.contains("Monstera deliciosa")); XCTAssertTrue(text.isHittable)
            }
            XCTAssertTrue(app.staticTexts["detailDisclaimer"].exists)
            capture("save-detail-" + uuid, app: app)
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func testSavePlantLocalFailureRetryWithoutNewCareRequest() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture", "--identification-candidates-fixture", "proposals", "--plant-creation-fixture", "error"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
        confirmCareAlternative(app)
        XCTAssertTrue(app.staticTexts["plantCreationError"].waitForExistence(timeout: 10))
        assertCareCount(1, app: app); assertInvocations(1, app: app); assertNoCreationReview(app)
        revealAboveInPhoto(app.images["identificationPhotoPreview"], app: app)
        capture("save-local-error", app: app)
        let change = app.buttons["changeConfirmedSpecies"]; revealInPhoto(change, app: app); change.tap()
        let cancel = app.buttons["cancelSpeciesSelection"]; revealInPhoto(cancel, app: app); cancel.tap()
        XCTAssertTrue(app.staticTexts["plantCreationError"].exists)
        assertCareCount(1, app: app)
        let retry = app.buttons["retryPlantCreation"]; revealInPhoto(retry, app: app); retry.tap()
        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForNonExistence(timeout: 10))
        XCTAssertEqual(createdCards(app).count, 1)
        capture("save-local-retry-collection", app: app)
        app.terminate(); app.launch()
        XCTAssertTrue(createdCards(app).firstMatch.waitForExistence(timeout: 8)); XCTAssertEqual(createdCards(app).count, 1)
    }

    func testSavePlantCommitLocksDismissalAndHasNoReview() {
        // Precommit remote cancellation belongs to CareSheetUITests; this
        // scenario covers the distinct, non-cancellable local commit boundary.
        let app = XCUIApplication()
        let id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--consent-test-id", id, "--identification-photo-fixture", "--identification-candidates-fixture", "proposals", "--plant-creation-fixture", "waiting"]
        app.launch(); prepareConsentPhoto(app); requestConsent(app)
        let accept = app.buttons["acceptExternalAIConsent"]; reveal(accept, in: app); accept.tap()
        XCTAssertTrue(app.buttons["speciesProposal-primary"].waitForExistence(timeout: 8))
        confirmCareAlternative(app)
        XCTAssertTrue(app.descendants(matching: .any)["plantCreationLoading"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["cancelIdentificationPhoto"].isEnabled)
        assertNoCreationReview(app); capture("save-commit-locked", app: app)
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForNonExistence(timeout: 25))
        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout: 10)); XCTAssertEqual(createdCards(app).count, 1)
        app.terminate(); app.launch()
        XCTAssertTrue(createdCards(app).firstMatch.waitForExistence(timeout: 8)); XCTAssertEqual(createdCards(app).count, 1)
    }

}

final class StoredCollectionUITests: PlantCareAIUITestCase {
    func testDetailRedesignCareGridAndFunctionalWatering() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "-AppleLanguages", "(es)"]
        app.launch()
        let card = app.buttons["plantCard-\(plantID(1))"]
        XCTAssertTrue(card.waitForExistence(timeout: 10)); card.tap()
        let name = app.staticTexts["selectedPlant-\(plantID(1))"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertEqual(name.label, "Fixture 1")
        XCTAssertTrue(app.buttons["editPlant-\(plantID(1))"].isHittable)
        capture("redesign-photo-identity", app: app)

        let register = app.buttons["detailRegisterCare-\(plantID(1))"]
        XCTAssertTrue(register.exists)
        reveal(register, in: app)
        XCTAssertTrue(register.isEnabled)
        XCTAssertEqual(register.label, "Registrar cuidado")
        XCTAssertFalse(app.staticTexts["detailWateringComingSoon"].exists)
        XCTAssertFalse(app.staticTexts["detailWateringUnavailable"].exists)
        XCTAssertGreaterThanOrEqual(register.frame.height, 44)
        capture("redesign-watering-preview", app: app)
        for text in ["Óptimo estado", "Sustrato moderadamente seco", "Riego recomendado hoy", "Ciclo: ~9-11 d"] {
            XCTAssertFalse(app.staticTexts[text].exists)
        }
        XCTAssertEqual(app.buttons.matching(identifier: "detailRegisterCare-\(plantID(1))").count, 1)
        XCTAssertFalse(app.buttons["Marcar como favorita"].exists)

        for (leftField, rightField) in [("light", "watering"), ("humidity", "temperature"), ("substrate", "fertilizer")] {
            let left = app.staticTexts["detailCare-\(leftField)-\(plantID(1))"]
            let right = app.staticTexts["detailCare-\(rightField)-\(plantID(1))"]
            reveal(left, in: app)
            XCTAssertTrue(right.isHittable)
            XCTAssertEqual(left.frame.minY, right.frame.minY, accuracy: 1)
            XCTAssertEqual(left.frame.width, right.frame.width, accuracy: 1)
            XCTAssertEqual(left.frame.height, right.frame.height, accuracy: 1)
            XCTAssertGreaterThan(right.frame.minX, left.frame.maxX)
            XCTAssertGreaterThanOrEqual(left.frame.minX, app.frame.minX + 19)
            XCTAssertLessThanOrEqual(right.frame.maxX, app.frame.maxX - 19)
        }
        capture("redesign-care-grid", app: app)
        back(app)
        app.terminate()
        app.launchArguments = ["--storage-test-id", id, "--storage-verify", "-AppleLanguages", "(es)"]
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
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
        openAndCheckBothDetails(app)
        XCTAssertFalse(app.staticTexts["emptyCollectionTitle"].exists)
        XCTAssertTrue(app.buttons["addPlantHeader"].isEnabled)
    }

}

extension PlantCareAIUITestCase {
    fileprivate func openEditor(_ index: Int, app: XCUIApplication) {
        let card = app.buttons["plantCard-\(plantID(index))"]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        for _ in 0..<15 where !card.isHittable { app.swipeDown() }
        reveal(card, in: app); card.tap()
        let edit = app.buttons["editPlant-\(plantID(index))"]
        XCTAssertTrue(edit.waitForExistence(timeout: 10)); edit.tap()
        XCTAssertTrue(app.navigationBars["Editar planta"].waitForExistence(timeout: 10))
    }

    fileprivate func replace(_ id: String, with value: String, app: XCUIApplication) {
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
            selectAllAndDelete(field, app: app, captureName: "edit-native-select-all", editorParagraphSelection: true)
            XCTAssertEqual(field.value as? String, "")
        }
        if !value.isEmpty { field.typeText(value) }
        XCTAssertEqual(field.value as? String, value)
    }

    fileprivate func saveEditor(_ app: XCUIApplication) {
        if app.keyboards.firstMatch.exists { finishTyping(app) }
        reveal(app.buttons["saveEditPlant"], in: app)
        app.buttons["saveEditPlant"].tap()
        XCTAssertTrue(app.navigationBars["Editar planta"].waitForNonExistence(timeout: 10))
    }

    fileprivate func finishTyping(_ app: XCUIApplication) {
        app.buttons["dismissEditPlantKeyboard"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    }

}

final class CareEventsUITests: PlantCareAIUITestCase {
    func testNativeCalendarPreviousDayAndFutureDisabled() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--care-fixture", "success", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        app.buttons["careKind-pruning"].tap()
        let picker = app.datePickers["careDate"]
        XCTAssertTrue(picker.exists); picker.tap()
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = .current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "es_ES")
        formatter.calendar = calendar; formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        if calendar.component(.month, from: tomorrow) == calendar.component(.month, from: today) {
            let future = app.buttons[formatter.string(from: tomorrow)]
            XCTAssertTrue(future.waitForExistence(timeout: 5)); XCTAssertFalse(future.isEnabled)
        } else { XCTAssertFalse(app.buttons["DatePicker.NextMonth"].isEnabled) }
        capture("care-native-calendar", app: app)
        if calendar.component(.month, from: yesterday) != calendar.component(.month, from: today) {
            app.buttons["DatePicker.PreviousMonth"].tap()
        }
        let previous = app.buttons[formatter.string(from: yesterday)]
        XCTAssertTrue(previous.waitForExistence(timeout: 5)); XCTAssertTrue(previous.isEnabled); previous.tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.1)).tap()
        XCTAssertTrue(app.buttons["careYesterday"].isSelected); XCTAssertFalse(app.buttons["careToday"].isSelected)
        save(app)
        verify(app, id: id, count: 1, extra: ["--storage-verify"] + expectations([["kind": "pruning", "note": NSNull(), "offset": -1]]))
    }

    private func expectations(_ values: [[String: Any]]) -> [String] {
        ["--care-expectations-base64", try! JSONSerialization.data(withJSONObject: values).base64EncodedString()]
    }

    func testExclusiveTogglePreservesNoteAndDateAndEveryKindSurvivesRelaunch() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--care-fixture", "success", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        capture("care-empty", app: app)
        app.buttons["careKind-fertilizing"].tap()
        XCTAssertTrue(app.buttons["careKind-fertilizing"].isSelected); XCTAssertTrue(app.buttons["saveCare"].isEnabled)
        capture("care-fertilizing", app: app)
        app.buttons["careYesterday"].tap()
        let note = app.textViews["careNote"]
        note.tap(); note.typeText("Abono\nSolo este ejemplar")
        app.buttons["dismissCareKeyboard"].tap()
        reveal(app.buttons["careKind-pruning"], in: app); app.buttons["careKind-pruning"].tap()
        XCTAssertFalse(app.buttons["careKind-fertilizing"].isSelected); XCTAssertTrue(app.buttons["careKind-pruning"].isSelected)
        app.buttons["careKind-pruning"].tap()
        XCTAssertFalse(app.buttons["careKind-pruning"].isSelected); XCTAssertFalse(app.buttons["saveCare"].isEnabled)
        XCTAssertTrue(app.buttons["careYesterday"].isSelected); XCTAssertEqual(note.value as? String, "Abono\nSolo este ejemplar")
        app.buttons["careKind-fertilizing"].tap(); save(app)
        var wanted: [[String: Any]] = [["kind": "fertilizing", "note": "Abono\nSolo este ejemplar", "offset": -1]]
        verify(app, id: id, count: 1, extra: ["--storage-verify"] + expectations(wanted))
        for kind in ["watering", "pruning", "repotting", "other"] {
            app.terminate(); app.launchArguments = ["--storage-test-id", id, "--care-fixture", "success", "-AppleLanguages", "(es)"]
            app.launch(); openWatering(app)
            app.buttons["careKind-\(kind)"].tap()
            let value = kind == "other" ? " \n " : "Nota \(kind)\nInterior"
            app.textViews["careNote"].tap(); app.textViews["careNote"].typeText(value)
            XCTAssertEqual(app.textViews["careNote"].value as? String, value)
            app.buttons["dismissCareKeyboard"].tap(); save(app)
            wanted.append(["kind": kind, "note": kind == "other" ? NSNull() : value, "offset": 0])
            verify(app, id: id, count: wanted.count, extra: ["--storage-verify"] + expectations(wanted))
        }
    }

    func testChangingKindAfterLocalErrorClearsRetryAndCommitsNewIntent() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--care-fixture", "fail-first", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        app.buttons["careKind-fertilizing"].tap(); reveal(app.buttons["saveCare"], in: app); app.buttons["saveCare"].tap()
        XCTAssertTrue(app.staticTexts["careError"].waitForExistence(timeout: 5))
        reveal(app.buttons["careKind-other"], in: app); app.buttons["careKind-other"].tap()
        XCTAssertFalse(app.staticTexts["careError"].exists); XCTAssertEqual(app.buttons["saveCare"].label, "Guardar cuidado")
        XCTAssertTrue(app.buttons["careKind-other"].isSelected); XCTAssertFalse(app.buttons["careKind-fertilizing"].isSelected)
        save(app)
        verify(app, id: id, count: 1, extra: ["--storage-verify"] + expectations([["kind": "other", "note": NSNull(), "offset": 0]]))
    }

    func testLongNamesMultilineNoteKeyboardScrollAndHomogeneousEditor() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--storage-long-text", "--care-fixture", "success", "-AppleLanguages", "(es)"]
        app.launch(); openEditor(1, app: app)
        let original = "Fixture 1: mi planta junto a la ventana del salón"
        XCTAssertEqual(app.staticTexts["plantFormName"].label, original)
        XCTAssertEqual(app.staticTexts["plantFormSubtitle"].label, "Monstera deliciosa — especie confirmada de este ejemplar")
        let edited = String(repeating: "Mi planta junto a la ventana del salón ", count: 8)
        replace("editPlantName", with: edited, app: app)
        XCTAssertEqual(app.staticTexts["plantFormName"].label, original) // Header is persisted opening snapshot, not draft.
        finishTyping(app)
        reveal(app.buttons["saveEditPlant"], in: app)
        XCTAssertTrue(app.buttons["saveEditPlant"].isHittable)
        XCTAssertLessThanOrEqual(app.buttons["saveEditPlant"].frame.maxX, app.frame.maxX)
        capture("edit-long-scroll", app: app)
        app.buttons["cancelEditPlant"].tap()
        openWatering(app, fromCollection: false)
        XCTAssertEqual(app.staticTexts["plantFormName"].label, original)
        app.buttons["careKind-watering"].tap()
        let note = app.textViews["careNote"]
        let value = String(repeating: "Agua para este ejemplar.\n", count: 25) + "Fin"
        note.tap(); note.typeText(value)
        XCTAssertEqual(note.value as? String, value)
        capture("watering-long-keyboard", app: app)
        app.buttons["dismissCareKeyboard"].tap()
        reveal(app.buttons["saveCare"], in: app)
        XCTAssertTrue(app.buttons["saveCare"].isHittable)
        XCTAssertLessThanOrEqual(app.buttons["saveCare"].frame.maxX, app.frame.maxX)
        capture("watering-long-scroll", app: app)
        save(app)
        verify(app, id: id, count: 1, extra: ["--storage-verify", "--storage-long-text", "--care-expected-note-base64", Data(value.utf8).base64EncodedString()])
    }
    private func openWatering(_ app: XCUIApplication, index: Int = 1, fromCollection: Bool = true) {
        if fromCollection {
            let card = app.buttons["plantCard-\(plantID(index))"]
            XCTAssertTrue(card.waitForExistence(timeout: 10)); reveal(card, in: app); card.tap()
        }
        let register = app.buttons["detailRegisterCare-\(plantID(index))"]
        XCTAssertTrue(register.waitForExistence(timeout: 10)); reveal(register, in: app); register.tap()
        XCTAssertTrue(app.navigationBars["Registrar cuidado"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["careToday"].isSelected)
        XCTAssertFalse(app.buttons["saveCare"].isEnabled)
        for (kind, label) in [("watering", "Riego"), ("fertilizing", "Abonado"), ("pruning", "Poda"), ("repotting", "Trasplante"), ("other", "Otro")] {
            XCTAssertFalse(app.buttons["careKind-\(kind)"].isSelected)
            XCTAssertEqual(app.buttons["careKind-\(kind)"].label, label)
        }
        let note = app.textViews["careNote"]
        XCTAssertEqual(note.value as? String, "")
        XCTAssertFalse(app.staticTexts["careConfirmation"].exists)
    }

    private func save(_ app: XCUIApplication) {
        let button = app.buttons["saveCare"]
        reveal(button, in: app); button.tap()
        XCTAssertTrue(app.navigationBars["Registrar cuidado"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["careConfirmation"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["careConfirmation"].firstMatch.label, "Cuidado registrado")
        XCTAssertFalse(app.buttons["Deshacer"].exists)
    }

    private func verify(_ app: XCUIApplication, id: String, count: Int, extra: [String] = []) {
        app.terminate()
        app.launchArguments = ["--storage-test-id", id, "--care-verify", String(count), "-AppleLanguages", "(es)"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["storageErrorMessage"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["careConfirmation"].firstMatch.exists)
    }

    func testThreeTapWateringRealCommitRelaunchAndNewIntentionSameDay() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--care-fixture", "success", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        XCTAssertTrue(app.staticTexts["Fixture 1"].exists)
        XCTAssertTrue(app.staticTexts["El registro se guardará exclusivamente para este ejemplar"].exists)
        XCTAssertEqual(app.buttons["saveCare"].label, "Guardar cuidado")
        XCTAssertEqual(app.buttons["cancelCare"].label, "Cancelar")
        capture("watering-default", app: app)
        app.buttons["careKind-watering"].tap()
        save(app) // Register + choose Riego + Save: exactly three taps from loaded detail.
        capture("watering-confirmed", app: app)
        verify(app, id: id, count: 1, extra: ["--storage-verify", "--care-expected-offset", "0"])
        app.terminate()
        app.launchArguments += ["--care-fixture", "success"]
        app.launch(); openWatering(app); app.buttons["careKind-watering"].tap(); save(app)
        verify(app, id: id, count: 2, extra: ["--storage-verify", "--care-expected-offset", "0"])
    }

    func testDateNoteCancelGestureAndFreshDraft() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--care-fixture", "success", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        app.buttons["careKind-watering"].tap()
        app.buttons["careYesterday"].tap()
        XCTAssertTrue(app.buttons["careYesterday"].isSelected)
        app.buttons["cancelCare"].tap()
        XCTAssertTrue(app.navigationBars["Registrar cuidado"].waitForNonExistence(timeout: 5))
        openWatering(app, fromCollection: false)
        let bar = app.navigationBars["Registrar cuidado"]
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.9)))
        XCTAssertTrue(bar.waitForNonExistence(timeout: 5))
        verify(app, id: id, count: 0, extra: ["--storage-verify"])
        app.terminate(); app.launchArguments += ["--care-fixture", "success"]; app.launch()
        openWatering(app); app.buttons["careKind-watering"].tap(); app.buttons["careYesterday"].tap()
        let note = app.textViews["careNote"]
        // Avoid iOS double-space-to-period keyboard substitution; still exercise trim and multiline input.
        let draft = " \nAgua\nSegunda línea\n "
        note.tap(); note.typeText(draft)
        XCTAssertEqual(note.value as? String, draft)
        capture("watering-keyboard-note", app: app)
        app.buttons["dismissCareKeyboard"].tap()
        save(app)
        verify(app, id: id, count: 1, extra: ["--storage-verify", "--care-expected-offset", "-1", "--care-expected-note-base64", Data("Agua\nSegunda línea".utf8).base64EncodedString()])
    }

    func testLocalFailureKeepsDraftAndRetryCommitsOnePayload() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--care-fixture", "fail-first", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        app.buttons["careKind-watering"].tap(); reveal(app.buttons["saveCare"], in: app); app.buttons["saveCare"].tap()
        let error = app.staticTexts["careError"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(error.label, "No se pudo guardar el cuidado en este dispositivo. Inténtalo de nuevo.")
        XCTAssertEqual(app.buttons["saveCare"].label, "Reintentar guardado")
        XCTAssertTrue(app.buttons["cancelCare"].isEnabled)
        capture("watering-local-error", app: app)
        save(app)
        verify(app, id: id, count: 1, extra: ["--storage-verify"])
    }

    func testBusyBlocksFieldsCancelAndGestureWithMissingPhoto() {
        let app = XCUIApplication(), id = isolatedID()
        app.launchArguments = ["--storage-test-id", id, "--storage-seed", "--storage-photo-missing", "--care-fixture", "busy", "-AppleLanguages", "(es)"]
        app.launch(); openWatering(app)
        capture("watering-placeholder", app: app)
        app.buttons["careKind-watering"].tap(); reveal(app.buttons["saveCare"], in: app); app.buttons["saveCare"].tap()
        XCTAssertTrue(app.activityIndicators["careSaving"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["cancelCare"].isEnabled)
        XCTAssertFalse(app.buttons["saveCare"].isEnabled)
        XCTAssertFalse(app.buttons["careYesterday"].isEnabled)
        XCTAssertFalse(app.buttons["careKind-fertilizing"].isEnabled)
        capture("watering-busy", app: app)
        let bar = app.navigationBars["Registrar cuidado"]
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.9)))
        XCTAssertTrue(bar.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["careConfirmation"].firstMatch.exists)
        verify(app, id: id, count: 1)
    }
}

final class EditPlantUITests: PlantCareAIUITestCase {
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
        XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(2))"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["selectedPlant-\(plantID(2))"].label, "Fixture 2")
        back(app)
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
        XCTAssertTrue(app.staticTexts["selectedPlant-\(plantID(2))"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["selectedPlant-\(plantID(2))"].label, "Fixture 2")
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

}

final class PlantCardsUITests: PlantCareAIUITestCase {
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
        let secondPhoto = app.descendants(matching: .any)["detailPhoto-\(plantID(2))"].firstMatch
        expectation(for: NSPredicate(format: "value == %@", "Foto cargada"), evaluatedWith: secondPhoto)
        waitForExpectations(timeout: 10)
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
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
        app.buttons["cancelIdentificationPhoto"].tap()
        XCTAssertTrue(app.staticTexts["storageErrorMessage"].waitForExistence(timeout: 5))
    }

}

final class IdentificationPhotoUITests: PlantCareAIUITestCase {
    func testIdentificationPhotoReplacementFailureCancellationAndEphemeralDraft() {
        let app = XCUIApplication()
        let storage = isolatedID()
        app.launchArguments = ["--storage-test-id", storage, "--identification-photo-fixture", "--photo-fixture-delay", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.exists)
        XCTAssertFalse(app.buttons["identifyPhoto"].isEnabled)
        XCTAssertEqual(app.staticTexts["identificationUnavailable"].label, "Identificar envía solo esta foto y una instrucción de identificación tras tu aceptación. No confirma la especie ni guarda una planta.")
        capture("photo-empty", app: app)
        app.buttons["takePlantPhoto"].tap()
        XCTAssertTrue(app.staticTexts["cameraIssue"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["cameraIssue"].label, "La cámara no está disponible en este dispositivo.")
        let a = app.buttons["fixture-photo-A"]
        reveal(a, in: app); a.tap()
        XCTAssertTrue(app.descendants(matching: .any)["photoLoading"].firstMatch.waitForExistence(timeout: 2))
        capture("photo-progress", app: app)
        let preview = app.images["identificationPhotoPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        XCTAssertEqual(preview.value as? String, "120 × 80")
        capture("photo-A", app: app)
        let failure = app.buttons["fixture-photo-failure"]
        reveal(failure, in: app); failure.tap()
        XCTAssertTrue(app.staticTexts["photoError"].waitForExistence(timeout: 10))
        XCTAssertEqual(preview.value as? String, "120 × 80")
        capture("photo-error-preserves-A", app: app)
        let b = app.buttons["fixture-photo-B"]
        reveal(b, in: app); b.tap()
        expectation(for: NSPredicate(format: "value == %@", "80 × 120"), evaluatedWith: preview)
        waitForExpectations(timeout: 10)
        capture("photo-B", app: app)
        app.buttons["cancelIdentificationPhoto"].tap()
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 5))
        app.buttons["addFirstPlant"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        let loadA = app.buttons["fixture-photo-A"]
        reveal(loadA, in: app); loadA.tap()
        app.buttons["cancelIdentificationPhoto"].tap()
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(preview.exists)
        // Keep empty-modal gesture coverage, then prove discard with a prepared A
        // and immediate reopen in this very process, before any terminate/launch.
        dismissPhotoByDrag(app, capturePrefix: "photo-gesture-empty")
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(preview.exists)
        let gestureA = app.buttons["fixture-photo-A"]
        reveal(gestureA, in: app); gestureA.tap()
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        XCTAssertEqual(preview.value as? String, "120 × 80")
        dismissPhotoByDrag(app, capturePrefix: "photo-gesture-with-A")
        app.buttons["addFirstPlant"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.exists)
        XCTAssertFalse(preview.exists)
        XCTAssertFalse(app.descendants(matching: .any)["photoLoading"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["photoError"].exists)
        XCTAssertFalse(app.buttons["identifyPhoto"].isEnabled)
        capture("photo-gesture-reopened-empty-after-A", app: app)
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 5))
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["identificationPhotoPlaceholder"].firstMatch.waitForExistence(timeout: 5))
    }

}

// This class runs separately on the seeded simulator, not on parallel clones.
final class SystemGalleryUITests: PlantCareAIUITestCase {
    func testRealGalleryPickerSelectReplaceCancelAndReselect() {
        let app = XCUIApplication()
        app.launchArguments = ["--storage-test-id", isolatedID(), "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()
        app.buttons["addPlantHeader"].tap()
        XCTAssertTrue(app.navigationBars["Foto de tu planta"].waitForExistence(timeout: 5))
        func select(_ index: Int) {
            app.buttons["chooseGalleryPhoto"].tap()
            let assets = app.images.matching(identifier: "PXGGridLayout-Info")
            XCTAssertTrue(assets.element(boundBy: index).waitForExistence(timeout: 10), app.debugDescription)
            let asset = assets.element(boundBy: index)
            XCTAssertGreaterThan(asset.frame.width, 0)
            XCTAssertTrue(app.frame.contains(asset.frame))
            capture("photo-real-picker-\(index)", app: app)
            // iOS 26 Photos exposes grid assets as Images without an AX hit point.
            // Tap the actual visible asset center; preview assertions verify selection.
            asset.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(app.navigationBars["Fotos"].waitForNonExistence(timeout: 10))
        }
        select(0)
        let preview = app.images["identificationPhotoPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        let first = preview.value as? String
        XCTAssertTrue(["160 × 80", "80 × 160"].contains(first ?? ""))
        capture("photo-real-first", app: app)
        app.buttons["chooseGalleryPhoto"].tap()
        let cancelPicker = app.navigationBars["Fotos"].buttons["Cancel"]
        XCTAssertTrue(cancelPicker.waitForExistence(timeout: 5))
        cancelPicker.tap()
        XCTAssertTrue(app.navigationBars["Fotos"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(preview.value as? String, first)
        select(1)
        expectation(for: NSPredicate(format: "value != %@", first ?? ""), evaluatedWith: preview)
        waitForExpectations(timeout: 10)
        XCTAssertTrue(["160 × 80", "80 × 160"].contains(preview.value as? String ?? ""))
        capture("photo-real-replacement", app: app)
        select(1) // same asset after PhotosPickerItem reset
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["identifyPhoto"])
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.buttons["identifyPhoto"].isEnabled)
        app.buttons["cancelIdentificationPhoto"].tap()
        XCTAssertTrue(app.staticTexts["emptyCollectionTitle"].waitForExistence(timeout: 5))
    }
}

final class LocalizationUITests: PlantCareAIUITestCase {
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
        XCTAssertFalse(app.staticTexts["Disponible cuando puedas elegir una foto."].exists)
        app.terminate()
        app.launchArguments += ["--storage-seed"]
        app.launch()
        XCTAssertTrue(app.buttons["plantCard-\(plantID(1))"].waitForExistence(timeout: 10))
        app.buttons["plantCard-\(plantID(1))"].tap()
        XCTAssertTrue(app.navigationBars["Detalle de planta"].waitForExistence(timeout: 10))
        assertDetail(1, app: app)
        let register = app.buttons["detailRegisterCare-\(plantID(1))"]
        reveal(register, in: app); register.tap()
        XCTAssertTrue(app.navigationBars["Registrar cuidado"].waitForExistence(timeout: 5))
        for (kind, label) in [("watering", "Riego"), ("fertilizing", "Abonado"), ("pruning", "Poda"), ("repotting", "Trasplante"), ("other", "Otro")] {
            XCTAssertEqual(app.buttons["careKind-\(kind)"].label, label)
        }
        XCTAssertFalse(app.buttons["saveCare"].isEnabled)
        app.buttons["cancelCare"].tap()
    }

}
