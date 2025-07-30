import SwiftUI

/// Text field component for entering search queries with change notification.
struct SearchInputView: View {
    @Binding var searchText: String
    let onChange: (String) -> Void

    var body: some View {
        TextField("Search...", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .onChange(of: searchText) { _, newValue in
                onChange(newValue)
            }
    }
}