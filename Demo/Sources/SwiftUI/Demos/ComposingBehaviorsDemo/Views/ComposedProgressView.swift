import LoadingView
import SwiftUI

/// Progress indicator showing loading state with optional progress percentage and active behaviors.
struct ComposedProgressView: View {
    let progress: LoadingProgress?
    let compositionType: CompositionType

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            if let progress {
                VStack(spacing: 8) {
                    Text(progress.message ?? "Loading...")
                        .font(.headline)

                    if let percent = progress.percent {
                        ProgressView(value: Double(percent), total: 100)
                            .frame(width: 200)

                        Text("\(percent)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("Active behaviors: \(compositionType.compositionOrder.dropFirst().joined(separator: " → "))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}