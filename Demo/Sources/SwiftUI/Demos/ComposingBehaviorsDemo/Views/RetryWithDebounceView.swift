import LoadingView
import SwiftUI

/// Demonstrates search functionality with debouncing wrapped in retry behavior.
struct RetryWithDebounceView: View {
    @State private var searchText = ""
    @State private var searchableBase: SearchableLoadable?
    @State private var loader: RetryableLoader<DebouncingLoadable<SearchableLoadable>>?

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
                ComposedLoadingView(loader: loader, compositionType: .retryWithDebounce)
            }
        }
        .task {
            await createLoader()
        }
    }

    @MainActor
    private func createLoader() async {
        // Base -> Debounce -> Retry
        let base = SearchableLoadable()
        searchableBase = base
        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.5
        )
        loader = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 3
        )
    }
}
