import XCTest

final class TatamiUITests: XCTestCase {
    @MainActor
    func testLaunchShowsRussianRecordingShell() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["record.toggle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["История"].exists)
        XCTAssertTrue(app.tabBars.buttons["Настройки"].exists)
    }
}
