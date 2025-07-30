import LoadingView
import SwiftUI

/// Main view that showcases different composition patterns of Loadable behaviors.
struct ComposingBehaviorsDemo: View {
    @State private var selectedComposition: CompositionType = .retryWithDebounce

    var body: some View {
        VStack(spacing: 20) {
            CompositionSelectorView(
                selectedComposition: $selectedComposition,
                onSelectionChange: { _ in }
            )

            CompositionDiagramView(compositionType: selectedComposition)
                .padding(.horizontal)

            Group {
                switch selectedComposition {
                case .retryWithDebounce:
                    RetryWithDebounceView()
                case .concurrencyWithRetry:
                    ConcurrencyWithRetryView()
                case .fullStack:
                    FullStackView()
                case .debounceWithConcurrency:
                    DebounceWithConcurrencyView()
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Composing Behaviors")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ComposingBehaviorsDemo()
    }
}