import LoadingView
import SwiftUI

struct StatisticsSection: View {
    let loader: BlockLoadable<Stats>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline)

            LoadingView(loader: loader) { stats in
                HStack(spacing: 20) {
                    StatBox(title: "Posts", value: "\(stats.posts)", color: .orange)
                    StatBox(title: "Followers", value: formatNumber(stats.followers), color: .purple)
                    StatBox(title: "Following", value: "\(stats.following)", color: .green)
                }
            }
            .progressView { _ in
                HStack(spacing: 20) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 80)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                }
            }
        }
    }

    func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}