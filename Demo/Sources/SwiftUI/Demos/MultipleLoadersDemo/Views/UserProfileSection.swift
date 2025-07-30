import LoadingView
import SwiftUI

struct UserProfileSection: View {
    let loader: BlockLoadable<User>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("User Profile", systemImage: "person.fill")
                .font(.headline)

            LoadingView(loader: loader) { user in
                HStack(spacing: 15) {
                    Image(systemName: user.avatar)
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text(user.status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            .progressView { _ in
                HStack {
                    ProgressView()
                    Text("Loading user profile...")
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}