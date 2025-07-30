import SwiftUI

/// Visual diagram showing the order of behavior composition for the selected pattern.
struct CompositionDiagramView: View {
    let compositionType: CompositionType

    var body: some View {
        VStack(spacing: 4) {
            Text("Composition Order:")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(Array(compositionType.compositionOrder.enumerated()), id: \.offset) { index, layer in
                    if index > 0 {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(layer)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }
}