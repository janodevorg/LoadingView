import LoadingView
import SwiftUI

struct ManualLoadingSection: View {
    let loader: BlockLoadable<String>
    @Binding var hasManuallyLoaded: Bool
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manual Loading")
                .font(.headline)

            Text("This LoadingView waits for you to trigger loading")
                .font(.caption)
                .foregroundColor(.secondary)

            LoadingView(loader: loader, loadOnAppear: false) { message in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text(message)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .emptyView {
                VStack(spacing: 10) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Press the button below to load")
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 100)

            Button(action: {
                hasManuallyLoaded = true
                isLoading = true
                Task {
                    loader.reset()
                    await loader.load()
                    isLoading = false
                }
            }, label: {
                Label(hasManuallyLoaded ? "Load Again" : "Start Loading",
                      systemImage: hasManuallyLoaded ? "arrow.clockwise" : "play.fill")
            })
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
