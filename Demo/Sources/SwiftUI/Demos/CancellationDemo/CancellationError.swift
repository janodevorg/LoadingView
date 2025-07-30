import Foundation

struct CancellationError: LocalizedError {
    var errorDescription: String? {
        "Operation was cancelled"
    }
}