// Add this fixture-driven UI test to a separate UI-testing target.
// It activates an already running app; prepare synthetic pages with LLDB first.
// testBackGestures checks cancellation followed by a completed navigation pop.
// testWebHistoryBack needs local pages A -> B; inspect WKWebView URL afterwards.
import XCTest

final class NavigationProbe: XCTestCase {
    @MainActor
    func testBackGestures() throws {
        let app = XCUIApplication(bundleIdentifier: "net.chanify.ios")
        app.activate()
        let sourceTitle = app.navigationBars.firstMatch.identifier
        let destinationTitle = app.navigationBars.buttons.firstMatch.label
        XCTAssertNotEqual(sourceTitle, destinationTitle)
        print("BEFORE NAV: " + app.navigationBars.debugDescription)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.45))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.45))
        let cancelEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: cancelEnd, withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.navigationBars[sourceTitle].waitForExistence(timeout: 3))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(app.navigationBars[destinationTitle].waitForExistence(timeout: 3))
        print("AFTER NAV: " + app.navigationBars.debugDescription)
    }
    @MainActor
    func testWebHistoryBack() throws {
        let app = XCUIApplication(bundleIdentifier: "net.chanify.ios")
        app.activate()
        XCTAssertTrue(app.navigationBars["Navigation B"].waitForExistence(timeout: 3))
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.45))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(app.navigationBars["Navigation web"].waitForExistence(timeout: 3))
    }

}
