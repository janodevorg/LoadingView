import SwiftUI
import LoadingView

/**
 Demonstrates how ConcurrencyLimitingLoadable limits concurrent operations

 # Concurrency Limiting Demo

 This demo showcases the `ConcurrencyLimitingLoadable` wrapper, which uses a token bucket pattern to limit the number of concurrent operations.

 ## Features Demonstrated

 1. **Token Bucket Pattern**: Limits concurrent operations without blocking threads
 2. **Task Suspension**: Queues excess operations using Swift's async/await
 3. **Progress Tracking**: Shows real-time download progress
 4. **Visual Feedback**: Displays active downloads and queue status

 ## How It Works

 The demo simulates downloading multiple items with a configurable concurrency limit:

 - **Total Items**: Choose 1-20 items to download
 - **Concurrency Limit**: Set maximum 1-10 simultaneous downloads
 - Each download takes 0.5-2.0 seconds (randomly)

 ## Key Components

 ### ConcurrencyLimitingLoadable
 ```swift
 let limitedLoader = ConcurrencyLimitingLoadable(
     wrapping: baseLoader,
     concurrencyLimit: 3
 )
 ```

 ### Benefits
 - Prevents server overload
 - Manages system resources efficiently
 - Maintains responsive UI
 - Works with any `Loadable` implementation

 ## Usage Scenarios

 - **API Rate Limiting**: Respect server rate limits
 - **Image Downloads**: Prevent memory pressure from too many concurrent downloads
 - **Batch Processing**: Control resource usage during heavy operations
 - **Network Requests**: Avoid overwhelming backend services

 ## Implementation Details

 The token bucket:
 1. Starts with N tokens (concurrency limit)
 2. Each operation consumes a token
 3. Operations wait (suspend) when no tokens available
 4. Tokens return to bucket when operations complete
 5. Waiting operations resume in FIFO order

 */
struct ConcurrencyLimitingDemo: View {
    @State private var loader: ConcurrencyLimitingLoadable<ParallelDownloadLoader>?
    @State private var concurrencyLimit = 3
    @State private var numberOfItems = 10

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                if let loader {
                    LoadingView(loader: loader) { results in
                        resultsView(results)
                    }
                    .progressView { progress in
                        progressView(progress)
                    }
                    .errorView { error in
                        errorView(HashableError(error))
                    }
                    .frame(minHeight: 200, maxHeight: 600)
                } else {
                    configurationSection
                }

                controlSection
            }
            .padding()
        }
        .navigationTitle("Concurrency Limiting")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if loader != nil {
                    Button("Reset") {
                        loader?.reset()
                        loader = nil
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Concurrency Limiting Demo")
                .font(.title2)
                .fontWeight(.bold)

            Text("This demo shows how ConcurrencyLimitingLoadable restricts the number of concurrent operations using a token bucket pattern.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var configurationSection: some View {
        ConfigurationView(
            numberOfItems: $numberOfItems,
            concurrencyLimit: $concurrencyLimit
        )
    }

    private func resultsView(_ results: [DownloadResult]) -> some View {
        DownloadResultsView(results: results, concurrencyLimit: concurrencyLimit)
    }

    private func progressView(_ progress: LoadingProgress?) -> some View {
        DownloadProgressView(
            progress: progress,
            totalItems: numberOfItems,
            concurrencyLimit: concurrencyLimit
        )
    }

    private func errorView(_ error: HashableError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Download Failed")
                .font(.headline)

            Text(error.error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var controlSection: some View {
        HStack(spacing: 16) {
            if loader != nil {
                Button("Reset") {
                    loader?.reset()
                    loader = nil
                }
                .buttonStyle(.bordered)
            } else {
                Button("Start Downloads") {
                    let baseLoader = ParallelDownloadLoader(itemCount: numberOfItems)
                    loader = ConcurrencyLimitingLoadable(
                        wrapping: baseLoader,
                        concurrencyLimit: concurrencyLimit
                    )
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Supporting Types

struct DownloadResult: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
}

@MainActor
final class ParallelDownloadLoader: BaseLoadable<[DownloadResult]>, Sendable {
    private let itemCount: Int
    private var completedCount = 0

    init(itemCount: Int) {
        self.itemCount = itemCount
        super.init()
    }

    override func fetch() async throws -> [DownloadResult] {
        var results: [DownloadResult] = []
        completedCount = 0

        // Update initial state
        updateState(.loading(LoadingProgress(
            message: "Preparing \(itemCount) downloads...",
            percent: 0
        )))

        // Simulate parallel downloads
        try await withThrowingTaskGroup(of: DownloadResult.self) { group in
            // Add all download tasks to the group
            for i in 1...itemCount {
                group.addTask { @Sendable in
                    // Simulate download with random duration
                    let duration = Double.random(in: 0.5...2.0)
                    let startTime = Date()

                    // Simulate the download work
                    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

                    let actualDuration = Date().timeIntervalSince(startTime)

                    return DownloadResult(
                        name: "Item \(i)",
                        duration: actualDuration
                    )
                }
            }

            // Collect results and update progress
            for try await result in group {
                results.append(result)
                completedCount += 1

                // Update progress after each completion
                let percent = (completedCount * 100) / itemCount
                updateState(.loading(LoadingProgress(
                    message: "Downloaded \(completedCount) of \(itemCount) items",
                    percent: percent
                )))
            }
        }

        return results.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConcurrencyLimitingDemo()
    }
}

// MARK: - LoadingState Extension

extension LoadingState {
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
