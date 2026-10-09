import XCTest

final class PlantCareAIUITests: XCTestCase {
    func testLaunchShowsBootstrapWithoutAddAction() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["bootstrapTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Preparando tu espacio para cuidar plantas."].exists)
        XCTAssertFalse(app.buttons["Añadir"].exists)
    }
}
