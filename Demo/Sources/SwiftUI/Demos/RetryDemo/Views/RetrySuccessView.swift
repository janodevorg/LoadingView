import SwiftUI

struct RetrySuccessView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text(message)
                .font(.title2)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}