import XCTest

final class PlantCareAIUITests: XCTestCase {
    func testLaunchShowsBootstrapWithoutAddAction() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        let title = app.staticTexts["bootstrapTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "PlantCare AI")
        XCTAssertTrue(app.staticTexts["Preparando tu espacio para cuidar plantas."].exists)
        XCTAssertFalse(app.buttons["Añadir"].exists)
    }

    func testEnglishPreferenceFallsBackToSpanishInsteadOfKeys() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let title = app.staticTexts["bootstrapTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "PlantCare AI")
        XCTAssertTrue(app.staticTexts["Preparando tu espacio para cuidar plantas."].exists)
    }
}
