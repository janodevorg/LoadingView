import SwiftUI

/// Displays successful search results with query and attempt metadata.
struct ComposedResultsView: View {
    let results: SearchResults
    let compositionType: CompositionType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Success!")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                if !results.query.isEmpty {
                    Label("Query: \(results.query)", systemImage: "magnifyingglass")
                        .font(.caption)
                }

                Label("Attempt #\(results.attemptNumber)", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Divider()

            ForEach(results.items, id: \.self) { item in
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                    Text(item)
                        .font(.callout)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}