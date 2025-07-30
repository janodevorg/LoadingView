import SwiftUI

struct CancellationErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 20) {
            if error is CancellationError {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Operation Cancelled")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("The operation was cancelled by user request")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                Text("Error")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(error.localizedDescription)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}