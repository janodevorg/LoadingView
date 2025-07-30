import SwiftUI

struct SearchHeaderView: View {
    @Binding var searchText: String
    @Binding var callCount: Int
    let actualCallCount: Int
    let onTextChange: (String) -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debounced Search Demo")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Type quickly to see debouncing in action. The search only executes 0.5 seconds after you stop typing.")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Search fruits...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) { _, newValue in
                    onTextChange(newValue)
                }

            HStack {
                Label("\(callCount) calls attempted", systemImage: "hand.tap.fill")
                    .foregroundColor(.orange)

                Spacer()

                Label("\(actualCallCount) actual API calls", systemImage: "network")
                    .foregroundColor(.green)
            }
            .font(.caption)

            Button("Reset Counters", action: onReset)
                .buttonStyle(.bordered)
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}