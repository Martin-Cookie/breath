import XCTest

final class StatsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOpensStatsFromToolbar() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState", "-UITestSkipOnboarding"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Řízené dýchání"].waitForExistence(timeout: 5))

        let chartButton = app.navigationBars["Řízené dýchání"].buttons.element(boundBy: 1)
        chartButton.tap()

        XCTAssertTrue(
            app.navigationBars["Statistiky"].waitForExistence(timeout: 3),
            "StatsView should open"
        )
        XCTAssertTrue(app.staticTexts["Průběh zadržení"].exists)
        XCTAssertTrue(app.staticTexts["Historie"].exists)
        XCTAssertTrue(app.staticTexts["Zatím žádná data"].exists, "Empty state visible with no sessions")
        XCTAssertTrue(app.buttons["7 dní"].exists, "Period picker shows current selection")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "StatsView-Empty"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testPremiumPeriodShowsPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestResetState", "-UITestSkipOnboarding"]
        app.launch()

        let chartButton = app.navigationBars["Řízené dýchání"].buttons.element(boundBy: 1)
        chartButton.tap()

        XCTAssertTrue(app.navigationBars["Statistiky"].waitForExistence(timeout: 3))

        // Period picker is a Menu — open it first to reveal options.
        app.buttons["7 dní"].tap()
        XCTAssertTrue(app.buttons["30 dní"].waitForExistence(timeout: 2))
        app.buttons["30 dní"].tap()

        XCTAssertTrue(
            app.staticTexts["Odemknout Breath Pro"].waitForExistence(timeout: 3),
            "Premium period should open paywall"
        )
    }
}
