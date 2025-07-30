import LoadingView
import SwiftUI

struct RetryProgressView: View {
    let progress: LoadingProgress?

    var body: some View {
        VStack(spacing: 20) {
            if let message = progress?.message, message.contains("Retrying") {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(360))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: progress?.message)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }

            if let message = progress?.message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}