import Foundation

/// Error types used in the composing behaviors demo to simulate various failure scenarios.
enum ComposingDemoError: LocalizedError {
    case networkError
    case emptyQuery
    case apiError(attempt: Int)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network request failed"
        case .emptyQuery:
            return "Please enter a search query"
        case .apiError(let attempt):
            return "API call failed (attempt \(attempt))"
        }
    }
}