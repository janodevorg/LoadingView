import Foundation

/// A loadable wrapper that adds automatic retry functionality with configurable attempts.
@MainActor
public final class RetryableLoader<Base: Loadable & Sendable>: Loadable {
    public private(set) var isCanceled = false
    public typealias Value = Base.Value

    private let loadable: Base
    private let maxAttempts: Int
    private let stateRelay = StateRelay<LoadingState<Value>>(.idle)
    private var monitorTask: Task<Void, Never>?
    private var hasStartedMonitoring = false

    public var state: any AsyncSequence<LoadingState<Value>, Never> {
        stateRelay.stream
    }

    public var currentState: LoadingState<Value> {
        stateRelay.currentValue
    }

    public init(wrapping: Base, maxAttempts: Int) {
        self.loadable = wrapping
        self.maxAttempts = maxAttempts
    }

    deinit {
        monitorTask?.cancel()
    }

    private func startMonitoringIfNeeded() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true

        monitorTask = Task { [weak self] in
            guard let self else { return }

            var attemptCount = 1  // Start at 1 for the initial attempt

            // Create the iterator BEFORE any load() calls to avoid race conditions
            for await state in loadable.state {
                guard !Task.isCancelled else { break }

                // Forward all states
                stateRelay.update(state)

                switch state {
                case .failure where attemptCount < maxAttempts:
                    attemptCount += 1

                    // Show retry message
                    stateRelay.update(.loading(LoadingProgress(
                        message: "Retrying… (attempt \(attemptCount) of \(maxAttempts))"
                    )))

                    // Wait with exponential backoff
                    try? await Task.sleep(
                        nanoseconds: UInt64(pow(2, Double(attemptCount - 2))) * 1_000_000_000
                    )

                    guard !isCanceled else { break }

                    // Don't reset the base loader - just retry
                    // This allows loaders like FlakeyLoader to maintain their internal state
                    await loadable.load()

                case .loaded:
                    // Success state - DON'T finish the stream immediately
                    // Let the consumer decide when to stop observing
                    break

                case .failure:
                    // Final failure (no more retries) - DON'T finish the stream
                    break

                case .loading, .idle:
                    // Continue monitoring
                    break
                }
            }
        }
    }

    public func cancel() {
        isCanceled = true
        loadable.cancel()
        monitorTask?.cancel()
    }

    public func reset() {
        isCanceled = false
        loadable.reset()
        stateRelay.update(.idle)

        // Cancel existing monitoring task and reset monitoring state
        // This ensures a fresh attemptCount when load() is called again
        monitorTask?.cancel()
        monitorTask = nil
        hasStartedMonitoring = false
    }

    public func load() async {
        guard !isCanceled else { return }

        // Ensure monitoring is started before the first load
        startMonitoringIfNeeded()

        // Trigger the base loader
        await loadable.load()
    }
}
