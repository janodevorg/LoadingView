import LoadingView
import SwiftUI

struct DownloadProgressView: View {
    let progress: LoadingProgress?
    let totalItems: Int
    let concurrencyLimit: Int
    @State private var animateProgress = false

    private var maxIndicators: Int {
        max(5, concurrencyLimit)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .scaleEffect(animateProgress ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateProgress)
            }

            VStack(spacing: 12) {
                Text("Downloading...")
                    .font(.headline)

                if let message = progress?.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let percent = progress?.percent {
                    VStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * (Double(percent) / 100), height: 8)
                                    .cornerRadius(4)
                                    .animation(.spring(), value: percent)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal)

                        Text("\(percent)% Complete")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }

                // Visual indicator of concurrency
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<maxIndicators, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index < concurrencyLimit ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 30, height: 4)
                        }
                    }

                    Text("Max concurrent: \(concurrencyLimit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: 300)
        .onAppear {
            animateProgress = true
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        DownloadProgressView(
            progress: LoadingProgress(
                message: "Downloaded 5 of 10 items",
                percent: 50
            ),
            totalItems: 10,
            concurrencyLimit: 3
        )

        DownloadProgressView(
            progress: LoadingProgress(
                message: "Preparing 10 downloads...",
                percent: 0
            ),
            totalItems: 10,
            concurrencyLimit: 2
        )
    }
}
