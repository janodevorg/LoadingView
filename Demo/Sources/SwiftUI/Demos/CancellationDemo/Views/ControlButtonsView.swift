import SwiftUI

struct ControlButtonsView: View {
    let isLoading: Bool
    let onStart: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onStart) {
                Label("Start", systemImage: "play.fill")
                    .frame(width: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button(action: onReset) {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .frame(width: 100)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}