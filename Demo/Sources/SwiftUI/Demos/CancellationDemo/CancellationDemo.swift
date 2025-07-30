import LoadingView
import SwiftUI

/// Shows how to implement cancellable loading operations with user controls.
struct CancellationDemo: View {
    @State private var loader = CancellableLoader()
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            LoadingView(loader: loader, loadOnAppear: false) { result in
                SuccessView(result: result)
            }
            .emptyView {
                EmptyStateView()
            }
            .progressView { progress in
                ProgressCircleView(progress: progress) {
                    loader.cancel()
                }
            }
            .errorView { error in
                CancellationErrorView(error: error)
            }

            Button(action: {
                isLoading = true
                Task {
                    loader.reset()
                    await loader.load()
                    isLoading = false
                }
            }) {
                Label("Start", systemImage: "play.fill")
                    .frame(width: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .navigationTitle("Cancellation")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
