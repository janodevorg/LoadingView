import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.semibold)
            Text(value)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}