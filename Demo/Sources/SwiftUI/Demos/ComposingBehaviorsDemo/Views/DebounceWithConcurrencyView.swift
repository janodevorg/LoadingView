import LoadingView
import SwiftUI

/// Demonstrates search with concurrency limiting wrapped in debouncing behavior.
struct DebounceWithConcurrencyView: View {
    @State private var searchText = ""
    @State private var searchableBase: SearchableLoadable?
    @State private var loader: DebouncingLoadable<ConcurrencyLimitingLoadable<SearchableLoadable>>?

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
                ComposedLoadingView(loader: loader, compositionType: .debounceWithConcurrency)
            }
        }
        .task {
            await createLoader()
        }
    }

    @MainActor
    private func createLoader() async {
        // Base -> Concurrency Limiting -> Debounce
        let base = SearchableLoadable()
        searchableBase = base
        let limited = ConcurrencyLimitingLoadable(
            wrapping: base,
            concurrencyLimit: 3
        )
        loader = await DebouncingLoadable(
            wrapping: limited,
            debounceInterval: 0.7
        )
    }
}