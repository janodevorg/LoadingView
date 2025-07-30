import SwiftUI

struct RetryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Configure retry settings above")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Then tap 'Apply Settings & Start' to begin")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}