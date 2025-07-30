import Foundation

/// Model representing the results of a search operation with metadata about the attempt.
struct SearchResults: Equatable, Hashable {
    let query: String
    let items: [String]
    let attemptNumber: Int
    let timestamp: Date
}