import LoadingView
import SwiftUI

/// Demonstrates the complete stack of behaviors: debounce, retry, and concurrency limiting.
struct FullStackView: View {
    @State private var searchText = ""
    @State private var searchableBase: SearchableLoadable?
    @State private var loader: ConcurrencyLimitingLoadable<RetryableLoader<DebouncingLoadable<SearchableLoadable>>>?

    var body: some View {
        VStack(spacing: 20) {
            SearchInputView(
                searchText: $searchText,
                onChange: { text in
                    searchableBase?.searchQuery = text
                    Task {
                        await loader?.load()
                    }
                }
            )

            if let loader {
                ComposedLoadingView(loader: loader, compositionType: .fullStack)
            }
        }
        .task {
            await createLoader()
        }
    }

    @MainActor
    private func createLoader() async {
        // Base -> Debounce -> Retry -> Concurrency Limiting
        let base = SearchableLoadable()
        searchableBase = base
        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.3
        )
        let retryable = RetryableLoader(
            base: debounced,
            maxAttempts: 2
        )
        loader = ConcurrencyLimitingLoadable(
            wrapping: retryable,
            concurrencyLimit: 1
        )
    }
}