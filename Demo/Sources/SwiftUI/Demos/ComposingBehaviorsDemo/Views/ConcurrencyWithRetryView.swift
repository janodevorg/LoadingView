import LoadingView
import SwiftUI

/// Demonstrates API calls with retry wrapped in concurrency limiting behavior.
struct ConcurrencyWithRetryView: View {
    @State private var loader: ConcurrencyLimitingLoadable<RetryableLoader<SimulatedAPILoader>>?

    var body: some View {
        VStack(spacing: 20) {
            if let loader {
                ComposedLoadingView(loader: loader, compositionType: .concurrencyWithRetry)
            }
        }
        .task {
            createLoader()
        }
    }

    @MainActor
    private func createLoader() {
        // Base -> Retry -> Concurrency Limiting
        let base = SimulatedAPILoader()
        let retryable = RetryableLoader(
            wrapping: base,
            maxAttempts: 3
        )
        loader = ConcurrencyLimitingLoadable(
            wrapping: retryable,
            concurrencyLimit: 2
        )
    }
}
