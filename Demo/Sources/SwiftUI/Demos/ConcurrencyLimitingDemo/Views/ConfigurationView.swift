import SwiftUI

struct ConfigurationView: View {
    @Binding var numberOfItems: Int
    @Binding var concurrencyLimit: Int

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration")
                    .font(.headline)

                HStack {
                    Label("Items to Download", systemImage: "square.stack.3d.down.right")
                        .foregroundColor(.primary)
                    Spacer()
                    Stepper("\(numberOfItems)", value: $numberOfItems, in: 1...20)
                }

                HStack {
                    Label("Concurrency Limit", systemImage: "hourglass.tophalf.filled")
                        .foregroundColor(.primary)
                    Spacer()
                    Stepper("\(concurrencyLimit)", value: $concurrencyLimit, in: 1...10)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("How it works:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                }

                Text("The loader will attempt to download \(numberOfItems) items, but only \(concurrencyLimit) downloads will run simultaneously. This prevents overwhelming the system while maintaining efficiency.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ConfigurationView(
        numberOfItems: .constant(10),
        concurrencyLimit: .constant(3)
    )
    .padding()
}