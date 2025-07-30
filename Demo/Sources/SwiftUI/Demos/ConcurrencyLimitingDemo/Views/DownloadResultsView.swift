import SwiftUI

struct DownloadResultsView: View {
    let results: [DownloadResult]
    let concurrencyLimit: Int

    private var sortedResults: [DownloadResult] {
        results.sorted { $0.name < $1.name }
    }

    private var statistics: (total: Int, averageDuration: Double, totalTime: Double, maxConcurrent: Int) {
        let total = results.count
        let totalTime = results.map(\.duration).reduce(0, +)
        let average = total > 0 ? totalTime / Double(total) : 0

        return (total, average, totalTime, concurrencyLimit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Download Complete")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Statistics Card
            statisticsCard

            // Results List
            VStack(alignment: .leading, spacing: 8) {
                Text("Download Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(sortedResults) { result in
                            DownloadResultRow(result: result)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private var statisticsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatisticView(
                    title: "Total",
                    value: "\(statistics.total)",
                    icon: "square.stack.3d.down.right.fill",
                    color: .blue
                )

                StatisticView(
                    title: "Avg Time",
                    value: String(format: "%.1fs", statistics.averageDuration),
                    icon: "timer",
                    color: .orange
                )
            }

            HStack(spacing: 16) {
                StatisticView(
                    title: "Total Time",
                    value: String(format: "%.1fs", statistics.totalTime),
                    icon: "clock.fill",
                    color: .green
                )

                StatisticView(
                    title: "Concurrent",
                    value: "\(statistics.maxConcurrent)",
                    icon: "arrow.triangle.branch",
                    color: .purple
                )
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(10)
    }
}

struct DownloadResultRow: View {
    let result: DownloadResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.green)
                .font(.caption)

            Text(result.name)
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Text("\(String(format: "%.1f", result.duration))s")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Duration indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 20, height: 20)

                Circle()
                    .trim(from: 0, to: min(result.duration / 3.0, 1.0))
                    .stroke(durationColor(for: result.duration), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }

    private func durationColor(for duration: Double) -> Color {
        if duration < 1.0 {
            return .green
        } else if duration < 2.0 {
            return .orange
        } else {
            return .red
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

#Preview {
    DownloadResultsView(
        results: [
            DownloadResult(name: "Item 1", duration: 0.8),
            DownloadResult(name: "Item 2", duration: 1.5),
            DownloadResult(name: "Item 3", duration: 2.1),
            DownloadResult(name: "Item 4", duration: 0.5),
            DownloadResult(name: "Item 5", duration: 1.2)
        ],
        concurrencyLimit: 3
    )
}