import XCTest

final class SessionFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStartAndCancelSession() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState", "-UITestSkipOnboarding"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Řízené dýchání"].waitForExistence(timeout: 5))

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        let roundLabel = app.staticTexts["Kolo 1 z 3"]
        XCTAssertTrue(roundLabel.waitForExistence(timeout: 3), "SessionView should show round indicator")

        let sessionScreenshot = app.screenshot()
        let sessionAttachment = XCTAttachment(screenshot: sessionScreenshot)
        sessionAttachment.name = "SessionView-Breathing"
        sessionAttachment.lifetime = .keepAlways
        add(sessionAttachment)

        let closeButton = app.buttons["session.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        closeButton.tap()

        let endButton = app.buttons["Ukončit"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 2), "Cancel confirmation dialog should appear")
        endButton.tap()

        XCTAssertTrue(
            app.navigationBars["Řízené dýchání"].waitForExistence(timeout: 3),
            "Should return to ConfigurationView after cancel"
        )
    }

    @MainActor
    func testOpensSettingsFromToolbar() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState", "-UITestSkipOnboarding"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Řízené dýchání"].waitForExistence(timeout: 5))

        let gearButton = app.navigationBars["Řízené dýchání"].buttons.firstMatch
        gearButton.tap()

        XCTAssertTrue(
            app.navigationBars["Nastavení"].waitForExistence(timeout: 3),
            "Settings sheet should open"
        )
        XCTAssertTrue(app.buttons["Smazat všechna data"].exists)
        XCTAssertTrue(app.buttons["Obnovit nákupy"].exists)

        let settingsScreenshot = app.screenshot()
        let settingsAttachment = XCTAttachment(screenshot: settingsScreenshot)
        settingsAttachment.name = "SettingsView"
        settingsAttachment.lifetime = .keepAlways
        add(settingsAttachment)
    }
}
