import SwiftUI

/// Error state view displaying error details with a retry action button.
struct ComposedErrorView: View {
    let error: Error
    let compositionType: CompositionType
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Error Occurred")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)

            Text("The composed behaviors will handle this retry")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}