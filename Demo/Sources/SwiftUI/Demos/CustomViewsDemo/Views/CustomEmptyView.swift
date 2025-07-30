import SwiftUI

struct CustomEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundColor(.indigo)
            Text("Nothing to see here yet")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Tap the reload button to start")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}