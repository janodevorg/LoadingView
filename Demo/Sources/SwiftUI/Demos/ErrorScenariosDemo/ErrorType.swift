import Foundation

enum ErrorType: String, CaseIterable {
    case network = "Network Error"
    case timeout = "Timeout Error"
    case validation = "Validation Error"
    case notFound = "Not Found (404)"
    case serverError = "Server Error (500)"
    case unauthorized = "Unauthorized (401)"

    var error: Error {
        switch self {
        case .network:
            return DemoError.networkError
        case .timeout:
            return DemoError.timeout
        case .validation:
            return DemoError.validationError
        case .notFound:
            return NSError(domain: "HTTP", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "The requested resource was not found"
            ])
        case .serverError:
            return NSError(domain: "HTTP", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Internal server error occurred"
            ])
        case .unauthorized:
            return NSError(domain: "HTTP", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Authentication required"
            ])
        }
    }
}