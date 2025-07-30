import SwiftUI

struct RetryErrorView: View {
    let error: Error
    let maxAttempts: Int

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Failed after \(maxAttempts) attempts")
                .font(.title2)
                .fontWeight(.bold)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}