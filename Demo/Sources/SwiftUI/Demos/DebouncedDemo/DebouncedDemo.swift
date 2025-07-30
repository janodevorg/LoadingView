import LoadingView
import SwiftUI

/// Illustrates debouncing to reduce API calls during rapid user input like search typing.
struct DebouncedDemo: View {
    @State private var searchText = ""
    @State private var callCount = 0
    @State private var baseLoader = DebouncedSearchLoader()
    @State private var debouncedLoader: DebouncingLoadable<DebouncedSearchLoader>?
    @State private var isResetting = false

    var body: some View {
        VStack(spacing: 0) {
            SearchHeaderView(
                searchText: $searchText,
                callCount: $callCount,
                actualCallCount: baseLoader.actualCallCount,
                onTextChange: { newValue in
                    // Don't increment counter during reset
                    if !isResetting {
                        callCount += 1
                        baseLoader.searchText = newValue
                        Task {
                            await debouncedLoader?.load()
                        }
                    }
                },
                onReset: {
                    isResetting = true
                    callCount = 0
                    baseLoader.actualCallCount = 0
                    searchText = ""
                    baseLoader.searchText = ""
                    debouncedLoader?.reset()
                    // Reset the flag after a brief delay to ensure the text change has propagated
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        isResetting = false
                    }
                }
            )

            if let loader = debouncedLoader {
                LoadingView(loader: loader, loadOnAppear: false) { results in
                    SearchResultsView(
                        results: results,
                        searchText: searchText,
                        actualCallCount: baseLoader.actualCallCount
                    )
                }
                .emptyView {
                    SearchPlaceholderView()
                }
            }
        }
        .navigationTitle("Debounced Loading")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            debouncedLoader = await DebouncingLoadable(
                wrapping: baseLoader,
                debounceInterval: 0.5,
                executeFirstImmediately: false
            )
        }
    }
}