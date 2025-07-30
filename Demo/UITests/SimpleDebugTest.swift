import XCTest

@MainActor
final class SimpleDebugTest: XCTestCase {

    func testDebugElements() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the app to fully load
        Thread.sleep(forTimeInterval: 2)

        print("\n=== DEBUG OUTPUT ===")
        print("All static texts:")
        for i in 0..<app.staticTexts.count {
            let text = app.staticTexts.element(boundBy: i)
            if text.exists {
                print("  - '\(text.label)'")
            }
        }

        print("\nAll buttons:")
        for i in 0..<app.buttons.count {
            let button = app.buttons.element(boundBy: i)
            if button.exists {
                print("  - '\(button.label)'")
            }
        }

        print("\nAll cells:")
        for i in 0..<app.cells.count {
            let cell = app.cells.element(boundBy: i)
            if cell.exists {
                print("  - '\(cell.label)'")
            }
        }

        print("\n=== Looking for Retry ===")
        let anyRetry = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS[c] 'retry'"))
        print("Elements containing 'retry': \(anyRetry.count)")
        for i in 0..<anyRetry.count {
            let element = anyRetry.element(boundBy: i)
            if element.exists {
                print("  - Type: \(element.elementType.rawValue), Label: '\(element.label)'")
            }
        }

        // Try to click on something
        if app.staticTexts["Retry on Failure"].exists {
            print("\nFound 'Retry on Failure' as static text!")
            app.staticTexts["Retry on Failure"].tap()

            // Wait and check what's visible after tap
            Thread.sleep(forTimeInterval: 2)
            print("\nAfter tapping, buttons are:")
            for i in 0..<app.buttons.count {
                let button = app.buttons.element(boundBy: i)
                if button.exists {
                    print("  - '\(button.label)'")
                }
            }
        }

        XCTAssertTrue(true) // Always pass, this is just for debugging
    }
}