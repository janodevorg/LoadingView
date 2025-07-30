import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Press 'Start' to begin a long operation")
                .foregroundColor(.secondary)

            Text("You can cancel it at any time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}