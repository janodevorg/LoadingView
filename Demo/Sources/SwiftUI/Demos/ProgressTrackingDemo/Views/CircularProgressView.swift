import LoadingView
import SwiftUI

struct CircularProgressView: View {
    let progress: LoadingProgress?

    var body: some View {
        VStack(spacing: 30) {
            if let percent = progress?.percent {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)

                    Circle()
                        .trim(from: 0, to: Double(percent) / 100)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: percent)

                    Text("\(percent)%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                }
                .frame(width: 200, height: 200)
            } else {
                ProgressView()
                    .scaleEffect(2)
            }

            if let message = progress?.message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.05))
    }
}