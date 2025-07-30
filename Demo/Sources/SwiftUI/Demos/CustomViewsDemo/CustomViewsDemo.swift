import LoadingView
import SwiftUI

/// Demonstrates customizing all loading states with tailored views for progress, error, and empty states.
struct CustomViewsDemo: View {
    @State private var loader = BlockLoadable {
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        // Randomly succeed or fail
        if Bool.random() {
            return "Success! Here's your content."
        } else {
            throw DemoError.randomFailure
        }
    }

    var body: some View {
        VStack {
            LoadingView(loader: loader) { content in
                CustomSuccessView(content: content)
            }
            .emptyView {
                CustomEmptyView()
            }
            .progressView { progress in
                CustomProgressView(progress: progress)
            }
            .errorView { error in
                CustomErrorView(error: error) {
                    Task {
                        loader.reset()
                        await loader.load()
                    }
                }
            }
        }
        .navigationTitle("Custom Views")
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