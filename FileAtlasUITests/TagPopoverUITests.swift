import XCTest

@MainActor
final class TagPopoverUITests: XCTestCase {
    func testSettingSuggestedTagKeepsTheAppRunning() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestTagPopover"]
        app.launch()

        let tagButton = app.buttons["tag-button"].firstMatch
        XCTAssertTrue(tagButton.waitForExistence(timeout: 5))
        tagButton.click()

        let videoTag = app.buttons["tag-option-video"]
        XCTAssertTrue(videoTag.waitForExistence(timeout: 3))
        videoTag.click()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3))
        XCTAssertTrue(app.staticTexts["Video"].waitForExistence(timeout: 3))
    }
}
