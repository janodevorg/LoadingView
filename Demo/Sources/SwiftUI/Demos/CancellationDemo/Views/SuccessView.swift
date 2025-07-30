import SwiftUI

struct SuccessView: View {
    let result: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text(result)
                .font(.title2)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}