import LoadingView
import SwiftUI

/// Compares automatic loading on appear versus manual loading triggered by user action.
struct ManualLoadingDemo: View {
    @State private var autoLoader = BlockLoadable {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "This loaded automatically when the view appeared!"
    }

    @State private var manualLoader = BlockLoadable {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "This loaded only when you pressed the button!"
    }

    @State private var hasManuallyLoaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                AutomaticLoadingSection(loader: autoLoader)
                    .frame(maxWidth: .infinity)

                Divider()

                ManualLoadingSection(
                    loader: manualLoader,
                    hasManuallyLoaded: $hasManuallyLoaded
                )
                .frame(maxWidth: .infinity)

                ExplanationSection()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Manual Loading")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}