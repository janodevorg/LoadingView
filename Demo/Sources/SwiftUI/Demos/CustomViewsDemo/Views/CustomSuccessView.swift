import SwiftUI

struct CustomSuccessView: View {
    let content: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text(content)
                .font(.title2)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}