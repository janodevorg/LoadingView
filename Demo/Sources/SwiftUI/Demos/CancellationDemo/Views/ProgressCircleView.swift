import LoadingView
import SwiftUI

struct ProgressCircleView: View {
    let progress: LoadingProgress?
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                if let percent = progress?.percent {
                    Circle()
                        .trim(from: 0, to: Double(percent) / 100)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: percent)
                }

                VStack {
                    if let percent = progress?.percent {
                        Text("\(percent)%")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    if progress?.isCanceled == true {
                        Text("Cancelling...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(width: 150, height: 150)

            if let message = progress?.message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Button(action: onCancel) {
                Label("Cancel Operation", systemImage: "xmark.circle.fill")
            }
            .buttonStyle(CancelButtonStyle())
            .disabled(progress?.isCanceled == true)
        }
    }
}

struct CancelButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isEnabled ? Color(red: 0.8, green: 0.2, blue: 0.2) : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}