import LoadingView
import SwiftUI

/// Generic loading view that displays the appropriate UI state for any composed loadable behavior.
struct ComposedLoadingView<L: Loadable & Sendable>: View where L.Value == SearchResults {
    let loader: L
    let compositionType: CompositionType

    var body: some View {
        LoadingView(loader: loader, loadOnAppear: !compositionType.requiresSearchInput) { results in
            ComposedResultsView(results: results, compositionType: compositionType)
        }
        .progressView { progress in
            ComposedProgressView(progress: progress, compositionType: compositionType)
        }
        .errorView { error in
            ComposedErrorView(error: error, compositionType: compositionType) {
                Task {
                    loader.reset()
                    await loader.load()
                }
            }
        }
        .emptyView {
            ComposedEmptyView(compositionType: compositionType)
        }
    }
}