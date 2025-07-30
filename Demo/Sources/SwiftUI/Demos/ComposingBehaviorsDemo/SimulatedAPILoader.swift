import Foundation
import LoadingView

/// A loadable that simulates API calls with progress updates and intentional failures for retry demonstration.
@MainActor
final class SimulatedAPILoader: BaseLoadable<SearchResults> {
    private var callCount = 0

    override func fetch() async throws -> SearchResults {
        callCount += 1

        // Update progress
        updateState(.loading(LoadingProgress(
            message: "Making API call \(callCount)...",
            percent: 0
        )))

        // Simulate API work with progress
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            updateState(.loading(LoadingProgress(
                message: "Processing... (\(i)/10)",
                percent: i * 10
            )))
        }

        // Fail first 2 attempts to show retry
        if callCount < 3 {
            throw ComposingDemoError.apiError(attempt: callCount)
        }

        return SearchResults(
            query: "API Call",
            items: ["API Result 1", "API Result 2", "API Result 3"],
            attemptNumber: callCount,
            timestamp: Date()
        )
    }

    override func reset() {
        super.reset()
        callCount = 0
    }
}