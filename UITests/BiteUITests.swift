import XCTest

final class BiteUITests: XCTestCase {
    @MainActor func testBrowseSaveAndRelaunch() throws {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["startExploring"].waitForExistence(timeout: 3) {
            app.buttons["startExploring"].tap()
        }
        let area = app.textFields["areaSearchField"]
        XCTAssertTrue(area.waitForExistence(timeout: 10))
        area.tap()
        area.typeText("San Francisco, CA")
        app.buttons["Search location"].tap()
        let result = app.buttons["restaurantResult"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 40), "Live restaurant search should return results")
        attach(app, name: "Live Discover")
        result.tap()
        let save = app.buttons["saveRestaurant"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        if !save.label.contains("Saved") { save.tap() }
        attach(app, name: "Real restaurant detail")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["savedRestaurant"].firstMatch.waitForExistence(timeout: 10))
        attach(app, name: "Saved after relaunch")
        app.tabBars.buttons["Map"].tap()
        XCTAssertTrue(app.buttons["Search this area"].waitForExistence(timeout: 10))
        attach(app, name: "Map")
    }

    @MainActor func testNearMeWithSimulatedLocation() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        app.launch()
        if app.buttons["startExploring"].waitForExistence(timeout: 2) { app.buttons["startExploring"].tap() }
        app.buttons["Near me"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow While Using App"]
        XCTAssertTrue(allow.waitForExistence(timeout: 10))
        allow.tap()
        XCTAssertTrue(app.buttons["restaurantResult"].firstMatch.waitForExistence(timeout: 40))
        app.tabBars.buttons["Map"].tap()
        XCTAssertTrue(app.buttons["Search this area"].waitForExistence(timeout: 10))
        attach(app, name: "Nearby map with real restaurants")
    }

    @MainActor func testLocationDeniedExplainsManualSearch() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
        app.launch()
        if app.buttons["startExploring"].waitForExistence(timeout: 2) { app.buttons["startExploring"].tap() }
        app.buttons["Near me"].tap()
        let deny = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        XCTAssertTrue(deny.waitForExistence(timeout: 10))
        deny.tap()
        XCTAssertTrue(app.buttons["Open Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.textFields["areaSearchField"].exists)
        attach(app, name: "Location denied fallback")
    }

    @MainActor private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
