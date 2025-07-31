import SwiftUI

/// Picker control that allows users to select between different composition patterns.
struct CompositionSelectorView: View {
    @Binding var selectedComposition: CompositionType
    let onSelectionChange: (CompositionType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pattern:")
                    .font(.headline)

                Spacer()

                Menu {
                    ForEach(CompositionType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedComposition = type
                            onSelectionChange(type)
                        }, label: {
                            Label(type.rawValue, systemImage: type.icon)
                        })
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedComposition.icon)
                        Text(selectedComposition.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }

            Text(selectedComposition.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
