import Foundation
import LoadingView

/// A loadable that performs search operations with simulated network delays and random failures.
@MainActor
final class SearchableLoadable: BaseLoadable<SearchResults> {
    var searchQuery: String = "" {
        didSet {
            if searchQuery != oldValue {
                attemptCount = 0
            }
        }
    }
    private var attemptCount = 0

    override func fetch() async throws -> SearchResults {
        attemptCount += 1

        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Randomly fail on first attempt to demonstrate retry
        if attemptCount == 1 && Bool.random() {
            throw ComposingDemoError.networkError
        }

        guard !searchQuery.isEmpty else {
            throw ComposingDemoError.emptyQuery
        }

        // Simulate search results
        let items = ["Success for API Request with string '\(searchQuery)'"]

        return SearchResults(
            query: searchQuery,
            items: items,
            attemptNumber: attemptCount,
            timestamp: Date()
        )
    }

    override func reset() {
        super.reset()
        attemptCount = 0
    }
}