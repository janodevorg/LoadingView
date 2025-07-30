import LoadingView
import SwiftUI

/// Showcases various error types and custom error handling views with retry capabilities.
struct ErrorScenariosDemo: View {
    @State private var selectedError: ErrorType = .network
    @State private var loader = ConfigurableErrorLoader()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ErrorSelectorView(
                selectedError: $selectedError,
                onTriggerError: {
                    // Configure the loader with the selected error
                    loader.errorToThrow = selectedError.error
                    loader.reset()

                    Task {
                        await loader.load()
                    }
                }
            )

            // Error display
            LoadingView(loader: loader, loadOnAppear: false) { _ in
                // This won't be shown as we always throw errors
                EmptyView()
            }
            .errorView { error in
                ErrorDetailsView(error: error) {
                    Task {
                        loader.reset()
                        await loader.load()
                    }
                }
            }
            .emptyView {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Select an error type and tap 'Trigger Error'")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("Error Scenarios")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}