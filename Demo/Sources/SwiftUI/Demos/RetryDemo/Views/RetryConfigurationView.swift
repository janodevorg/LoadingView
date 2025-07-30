import SwiftUI

struct RetryConfigurationView: View {
    @Binding var maxAttempts: Int
    @Binding var successAfter: Int
    let onStartTest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure Retry Behavior")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading) {
                Text("Max Retry Attempts: \(maxAttempts)")
                    .font(.headline)
                Slider(
                    value: Binding(
                        get: { Double(maxAttempts) },
                        set: { maxAttempts = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                )
                Text("Maximum number of retry attempts before giving up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading) {
                Text("Succeed After: \(successAfter) attempts")
                    .font(.headline)
                Slider(
                    value: Binding(
                        get: { Double(successAfter) },
                        set: { successAfter = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                )
                Text("Number of attempts before the operation succeeds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if successAfter > maxAttempts {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Warning: Success attempts (\(successAfter)) exceeds max retries (\(maxAttempts)). This will always fail.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 8)
            }

            Button("Start Test", action: onStartTest)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("Start Test")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}