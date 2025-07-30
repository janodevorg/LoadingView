@testable import LoadingView
import XCTest

struct CustomError: Error, LocalizedError, Sendable {
    var errorDescription: String? {
        "Custom error occurred"
    }
}

final class LoadingStateTests: XCTestCase {
    func testErrorStateOutputsLocalizedDescription() {
        let error = CustomError()
        let loadingState: LoadingState<String> = .failure(error)
        XCTAssertEqual(
            loadingState.description,
            "Custom error occurred",
            "The description of the error state should output the localized description of the custom error"
        )
    }
}
