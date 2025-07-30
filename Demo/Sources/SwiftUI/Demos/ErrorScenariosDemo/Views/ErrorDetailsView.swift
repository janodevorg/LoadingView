import SwiftUI

struct ErrorDetailsView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Error icon based on type
                Image(systemName: ErrorHelper.errorIcon(for: error))
                    .font(.system(size: 60))
                    .foregroundColor(ErrorHelper.errorColor(for: error))

                Text(ErrorHelper.errorTitle(for: error))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Error details
                if let nsError = error as NSError? {
                    ErrorMetadataView(nsError: nsError)
                }

                // Recovery suggestions
                RecoverySuggestionsView(suggestions: ErrorHelper.recoverySuggestions(for: error))

                Button("Try Again", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct ErrorMetadataView: View {
    let nsError: NSError

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DetailRow(label: "Domain", value: nsError.domain)
            DetailRow(label: "Code", value: String(nsError.code))

            if !nsError.userInfo.isEmpty {
                Text("User Info:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.top, 5)

                ForEach(Array(nsError.userInfo.keys), id: \.self) { key in
                    if let value = nsError.userInfo[key] {
                        DetailRow(
                            label: String(describing: key),
                            value: String(describing: value)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .font(.caption)
    }
}

struct RecoverySuggestionsView: View {
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recovery Suggestions:")
                .font(.headline)

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(suggestion)
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}