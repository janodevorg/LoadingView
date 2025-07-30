import XCTest

@MainActor
final class RetryDemoUITests: XCTestCase {

    func testStartButtonCreatesLoadersAndStartsLoading() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the app to fully load
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))

        // Navigate to Retry on Failure demo using accessibility identifier
        let retryDemoLink = app.buttons.matching(identifier: "Retry on Failure").firstMatch
        XCTAssertTrue(retryDemoLink.waitForExistence(timeout: 5), "Could not find Retry on Failure navigation link")
        retryDemoLink.tap()

        // Wait for navigation to complete
        Thread.sleep(forTimeInterval: 0.5)

        // Find the Start Test button
        let startButton = app.buttons["Start Test"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))

        // Verify initial state - no loading view
        XCTAssertFalse(app.staticTexts["Loading..."].exists)

        // Tap Start Test
        startButton.tap()

        // Verify loading starts
        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: 2))

        // Wait for success message (default is 3 attempts with 1 second each)
        let successMessage = app.staticTexts["Finally connected after 3 attempts!"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 10))
    }

    func testStartButtonResetsWhenSettingsUnchanged() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Retry on Failure demo using accessibility identifier
        let retryDemoLink = app.buttons.matching(identifier: "Retry on Failure").firstMatch
        XCTAssertTrue(retryDemoLink.waitForExistence(timeout: 5), "Could not find Retry on Failure navigation link")
        retryDemoLink.tap()

        // Wait for navigation to complete
        Thread.sleep(forTimeInterval: 0.5)

        // First test run
        let startButton = app.buttons["Start Test"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Wait for first success
        let successMessage = app.staticTexts["Finally connected after 3 attempts!"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 10))

        // Tap Start Test again without changing settings
        startButton.tap()

        // Should see loading again (indicates reset)
        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: 2))

        // Should see success again
        XCTAssertTrue(successMessage.waitForExistence(timeout: 10))
    }

    func testStartButtonCreatesNewLoadersWhenSettingsChange() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Retry on Failure demo using accessibility identifier
        let retryDemoLink = app.buttons.matching(identifier: "Retry on Failure").firstMatch
        XCTAssertTrue(retryDemoLink.waitForExistence(timeout: 5), "Could not find Retry on Failure navigation link")
        retryDemoLink.tap()

        // Wait for navigation to complete
        Thread.sleep(forTimeInterval: 0.5)

        // Change success after attempts
        let successSlider = app.sliders["Succeed After: 3 attempts"]
        XCTAssertTrue(successSlider.waitForExistence(timeout: 5))
        successSlider.adjust(toNormalizedSliderPosition: 0.5) // Move to ~5

        // Start test
        let startButton = app.buttons["Start Test"]
        startButton.tap()

        // Should see loading
        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: 2))

        // Wait for success with new attempt count
        let successPattern = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Finally connected after'"))
        XCTAssertTrue(successPattern.element.waitForExistence(timeout: 15))
    }

    func testWarningAppearsWhenSuccessExceedsMaxRetries() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Retry on Failure demo using accessibility identifier
        let retryDemoLink = app.buttons.matching(identifier: "Retry on Failure").firstMatch
        XCTAssertTrue(retryDemoLink.waitForExistence(timeout: 5), "Could not find Retry on Failure navigation link")
        retryDemoLink.tap()

        // Wait for navigation to complete
        Thread.sleep(forTimeInterval: 0.5)

        // Set max attempts to 3
        let maxAttemptsSlider = app.sliders["Max Retry Attempts: 5"]
        XCTAssertTrue(maxAttemptsSlider.waitForExistence(timeout: 5))
        maxAttemptsSlider.adjust(toNormalizedSliderPosition: 0.2) // ~3

        // Set success after to 5
        let successSlider = app.sliders.matching(NSPredicate(format: "label CONTAINS 'Succeed After:'")).element
        successSlider.adjust(toNormalizedSliderPosition: 0.5) // ~5

        // Check for warning
        let warningText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Warning: Success attempts'"))
        XCTAssertTrue(warningText.element.waitForExistence(timeout: 2))

        // Start test - should fail
        let startButton = app.buttons["Start Test"]
        startButton.tap()

        // Should see error after max attempts
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Failed after'"))
        XCTAssertTrue(errorText.element.waitForExistence(timeout: 10))
    }
}

// Helper extension for normalized slider position
extension XCUIElement {
    func adjust(toNormalizedSliderPosition normalizedSliderPosition: CGFloat) {
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
        let end = coordinate(withNormalizedOffset: CGVector(dx: normalizedSliderPosition, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}