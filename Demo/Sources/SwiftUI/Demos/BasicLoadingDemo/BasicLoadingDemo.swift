import LoadingView
import SwiftUI

/// Demonstrates the simplest use case of LoadingView with automatic loading on appear.
struct BasicLoadingDemo: View {
    @State private var loader = BlockLoadable {
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        return ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    }

    var body: some View {
        VStack {
            LoadingView(loader: loader) { fruits in
                FruitListView(fruits: fruits)
            }
            .progressView { _ in
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading fruits...")
                        .padding(.top)
                }
            }
        }
        .navigationTitle("Basic Loading")
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
