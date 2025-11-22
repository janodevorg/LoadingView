import Foundation
import LoadingView

@MainActor
class ProgressTrackingLoader: BaseLoadable<[String]> {
    override func load() async {
        guard !isCanceled else { return }

        // Simulate a multi-step process with progress updates
        updateState(.loading(LoadingProgress(
            message: "Connecting to server...",
            percent: 0
        )))

        do {
            try await Task.sleep(nanoseconds: 500_000_000)

            updateState(.loading(LoadingProgress(
                message: "Authenticating...",
                percent: 20
            )))

            try await Task.sleep(nanoseconds: 500_000_000)

            updateState(.loading(LoadingProgress(
                message: "Fetching data...",
                percent: 40
            )))

            try await Task.sleep(nanoseconds: 500_000_000)

            updateState(.loading(LoadingProgress(
                message: "Processing results...",
                percent: 60
            )))

            try await Task.sleep(nanoseconds: 500_000_000)

            updateState(.loading(LoadingProgress(
                message: "Finalizing...",
                percent: 80
            )))

            try await Task.sleep(nanoseconds: 500_000_000)

            updateState(.loading(LoadingProgress(
                message: "Almost done...",
                percent: 95
            )))

            try await Task.sleep(nanoseconds: 200_000_000)

            let results = [
                "Connection established",
                "Authentication successful",
                "Data retrieved (2.5MB)",
                "Processing completed",
                "42 items loaded"
            ]

            updateState(.loaded(results))
        } catch {
            if !isCanceled {
                updateState(.failure(error))
            }
        }
    }
}
