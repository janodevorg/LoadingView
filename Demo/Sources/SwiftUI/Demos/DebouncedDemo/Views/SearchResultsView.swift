import SwiftUI

struct SearchResultsView: View {
    let results: [String]
    let searchText: String
    let actualCallCount: Int

    var body: some View {
        if results.isEmpty && !searchText.isEmpty {
            NoResultsView(searchText: searchText, actualCallCount: actualCallCount)
        } else if !results.isEmpty {
            List(results, id: \.self) { fruit in
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text(fruit)
                }
            }
        } else {
            SearchPlaceholderView()
        }
    }
}

struct NoResultsView: View {
    let searchText: String
    let actualCallCount: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No fruits found matching '\(searchText)'")
                .foregroundColor(.secondary)
            Text("API call #\(actualCallCount) completed")
                .font(.caption)
                .foregroundColor(.green)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct SearchPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Start typing to search")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}