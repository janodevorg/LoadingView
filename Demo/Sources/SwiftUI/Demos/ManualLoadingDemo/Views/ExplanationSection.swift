import SwiftUI

struct ExplanationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("How it works", systemImage: "info.circle")
                .font(.headline)

            Text("""
            LoadingView has a `loadOnAppear` parameter:

            • `true` (default): Automatically calls load() when view appears
            • `false`: You must manually call load() on the loader

            This is useful for scenarios where you want precise control over when loading begins, such as after user input or other conditions are met.
            """)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}