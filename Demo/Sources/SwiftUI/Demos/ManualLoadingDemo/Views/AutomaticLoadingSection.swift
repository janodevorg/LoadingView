import LoadingView
import SwiftUI

struct AutomaticLoadingSection: View {
    let loader: BlockLoadable<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Automatic Loading")
                .font(.headline)

            Text("This LoadingView starts loading immediately when it appears")
                .font(.caption)
                .foregroundColor(.secondary)

            LoadingView(loader: loader, loadOnAppear: true) { message in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }
            .frame(height: 100)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}