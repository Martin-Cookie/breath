import XCTest

final class PaywallUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTappingSlowSpeedOpensPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState", "-UITestSkipOnboarding"]
        app.launch()

        XCTAssertTrue(
            app.navigationBars["Řízené dýchání"].waitForExistence(timeout: 5),
            "ConfigurationView should be visible"
        )

        let slowButton = app.buttons["Pomalé"]
        XCTAssertTrue(slowButton.waitForExistence(timeout: 3), "Slow speed button should exist")
        slowButton.tap()

        let paywallTitle = app.staticTexts["Odemknout Breath Pro"]
        XCTAssertTrue(paywallTitle.waitForExistence(timeout: 3), "Paywall should open on slow speed tap")

        XCTAssertTrue(app.staticTexts["Všechny rychlosti dýchání"].exists, "Speeds feature should be listed")
        XCTAssertTrue(app.staticTexts["Kompletní historie a grafy"].exists, "History feature should be listed")
        XCTAssertTrue(app.buttons["Obnovit nákupy"].exists, "Restore button should exist")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Paywall"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testConfigurationViewBasicLayout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState", "-UITestSkipOnboarding"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Řízené dýchání"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Standardní"].exists)
        XCTAssertTrue(app.buttons["Start"].exists)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ConfigurationView"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testOnboardingShowsOnFirstLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Vítej v Breath"].waitForExistence(timeout: 5),
            "Onboarding welcome screen should appear on first launch"
        )

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Onboarding"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
