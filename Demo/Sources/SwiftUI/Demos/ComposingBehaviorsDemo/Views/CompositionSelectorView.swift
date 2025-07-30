import SwiftUI

/// Picker control that allows users to select between different composition patterns.
struct CompositionSelectorView: View {
    @Binding var selectedComposition: CompositionType
    let onSelectionChange: (CompositionType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Composition Pattern")
                .font(.headline)

            Picker("Composition", selection: $selectedComposition) {
                ForEach(CompositionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedComposition) { _, newValue in
                onSelectionChange(newValue)
            }

            Text(selectedComposition.description)
                .font(.caption)
                .foregroundColor(.secondary)

            CompositionDiagramView(compositionType: selectedComposition)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}