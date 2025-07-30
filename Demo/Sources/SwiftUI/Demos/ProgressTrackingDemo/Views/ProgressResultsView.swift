import SwiftUI

struct ProgressResultsView: View {
    let results: [String]

    var body: some View {
        List(results, id: \.self) { result in
            HStack {
                Text(result)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}