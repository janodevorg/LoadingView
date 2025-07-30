import LoadingView
import SwiftUI

struct RecentActivitySection: View {
    let loader: BlockLoadable<[String]>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Recent Activity", systemImage: "clock.fill")
                .font(.headline)

            LoadingView(loader: loader) { activities in
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                        HStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                            Text(activity)
                                .font(.caption)
                            Spacer()
                            Text("\(index + 1)h ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .progressView { _ in
                VStack(spacing: 8) {
                    ForEach(0..<4) { _ in
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 16)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}