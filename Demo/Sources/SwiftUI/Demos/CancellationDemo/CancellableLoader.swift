import Foundation
import LoadingView

@MainActor
class CancellableLoader: BaseLoadable<String> {
    var wasCancelled = false

    override func reset() {
        super.reset()
        wasCancelled = false
    }

    override func cancel() {
        // Only update if not already cancelled to prevent infinite loop
        guard !isCanceled else { return }

        super.cancel()
        // Update the state to show cancellation
        updateState(.loading(LoadingProgress(
            isCanceled: true,
            message: "Cancelled",
            percent: nil
        )))
    }

    override func load() async {
        guard !isCanceled else { return }

        updateState(.loading(nil))

        do {
            // Simulate a long operation with multiple checkpoints
            for i in 1...10 {
                if isCanceled {
                    wasCancelled = true
                    // Update state to show cancelled
                    updateState(.loading(LoadingProgress(
                        isCanceled: true,
                        message: "Cancelled at step \(i)",
                        percent: i * 10
                    )))
                    throw CancellationError()
                }

                updateState(.loading(LoadingProgress(
                    isCanceled: false,
                    message: "Processing step \(i) of 10...",
                    percent: i * 10
                )))

                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds per step
            }

            let result = "Operation completed successfully!"
            updateState(.loaded(result))
        } catch {
            if !isCanceled {
                updateState(.failure(error))
            }
        }
    }
}
