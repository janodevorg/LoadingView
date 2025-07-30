import SwiftUI

/// Empty state view with instructions based on the selected composition type.
struct ComposedEmptyView: View {
    let compositionType: CompositionType

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Results")
                .font(.headline)

            if compositionType.requiresSearchInput {
                Text("Enter a search query to see composed behaviors in action")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Click to start loading with composed behaviors")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}