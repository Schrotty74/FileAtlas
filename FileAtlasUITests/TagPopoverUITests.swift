import XCTest

@MainActor
final class TagPopoverUITests: XCTestCase {
    func testSettingSuggestedTagKeepsTheAppRunning() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestTagPopover"]
        app.launch()

        // The test fixture lists the sample folder before the sample video.
        // Select the video row's tag button so that "Video" is suggested.
        let tagButton = app.buttons.matching(identifier: "tag-button").element(boundBy: 1)
        XCTAssertTrue(tagButton.waitForExistence(timeout: 5))
        tagButton.click()

        let videoTag = app.buttons["tag-option-video"]
        XCTAssertTrue(videoTag.waitForExistence(timeout: 3))
        videoTag.click()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3))
        let tagWasApplied = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Video"),
            object: tagButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [tagWasApplied], timeout: 3), .completed)
    }
}
