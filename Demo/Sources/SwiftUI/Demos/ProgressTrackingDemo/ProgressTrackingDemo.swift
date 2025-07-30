import LoadingView
import SwiftUI

/// Shows real-time progress updates during long-running operations with circular progress indicator.
struct ProgressTrackingDemo: View {
    @State private var loader = ProgressTrackingLoader()

    var body: some View {
        VStack {
            LoadingView(loader: loader) { results in
                ProgressResultsView(results: results)
            }
            .progressView { progress in
                CircularProgressView(progress: progress)
            }
        }
        .navigationTitle("Progress Tracking")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Reload") {
                    Task {
                        loader.reset()
                        await loader.load()
                    }
                }
            }
        }
    }
}