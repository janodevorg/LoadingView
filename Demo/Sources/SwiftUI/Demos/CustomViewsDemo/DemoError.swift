import Foundation

enum DemoError: LocalizedError {
    case randomFailure
    case networkError
    case validationError
    case timeout

    var errorDescription: String? {
        switch self {
        case .randomFailure: "Random failure occurred. Try again!"
        case .networkError: "Network connection failed"
        case .validationError: "Invalid data received"
        case .timeout: "Request timed out"
        }
    }
}