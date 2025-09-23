import Foundation
import Observation

/// A loadable wrapper that limits the number of concurrent load operations using a token bucket pattern.
///
/// This wrapper ensures that only a limited number of load operations can execute concurrently.
/// When the limit is reached, subsequent operations are suspended (not blocked) until a token becomes available.
///
/// Example usage:
/// ```swift
/// let limitedLoader = ConcurrencyLimitingLoadable(
///     wrapping: baseLoader,
///     concurrencyLimit: 3
/// )
///
/// // Only 3 of these will execute concurrently
/// for i in 1...10 {
///     Task {
///         await limitedLoader.load()
///     }
/// }
/// ```
@Observable
@MainActor
public final class ConcurrencyLimitingLoadable<Base: Loadable & Sendable>: Loadable {
    public typealias Value = Base.Value

    private let base: Base
    private let tokenBucket: TokenBucket
    public var currentState: LoadingState<Value> = .idle
    private var monitorTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var hasStartedMonitoring = false

    public private(set) var isCanceled = false

    public var state: any AsyncSequence<LoadingState<Value>, Never> {
        Observations {
            self.currentState
        }
    }

    /// Initializes a new concurrency-limited loadable.
    /// - Parameters:
    ///   - wrapping: The base loadable to wrap
    ///   - concurrencyLimit: Maximum number of concurrent load operations (must be > 0)
    public init(wrapping base: Base, concurrencyLimit: Int) {
        precondition(concurrencyLimit > 0, "Concurrency limit must be greater than 0")
        self.base = base
        self.tokenBucket = TokenBucket(tokens: concurrencyLimit)
    }

    isolated deinit {
        monitorTask?.cancel()
        loadTask?.cancel()
    }

    private func startMonitoringIfNeeded() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true

        monitorTask = Task { [weak self] in
            guard let self else { return }

            for await state in base.state {
                guard !Task.isCancelled else { break }
                currentState = state
            }
        }
    }

    public func load() async {
        guard !isCanceled else { return }

        startMonitoringIfNeeded()

        // Use token bucket to limit concurrency
        loadTask = Task { @MainActor in
            do {
                try await tokenBucket.withToken { @MainActor in
                    // Only execute if not canceled
                    guard !self.isCanceled else { return }
                    await self.base.load()
                }
            } catch {
                // Token bucket operations were cancelled
                if !self.isCanceled {
                    self.currentState = .failure(ConcurrencyLimitError.tokenAcquisitionFailed)
                }
            }
        }

        await loadTask?.value
    }

    public func cancel() {
        isCanceled = true
        base.cancel()
        loadTask?.cancel()
        monitorTask?.cancel()
    }

    public func reset() {
        isCanceled = false
        base.reset()
        currentState = .idle

        // Cancel existing tasks and reset monitoring state
        loadTask?.cancel()
        loadTask = nil
        monitorTask?.cancel()
        monitorTask = nil
        hasStartedMonitoring = false
    }
}

/// Errors specific to concurrency limiting operations.
public enum ConcurrencyLimitError: LocalizedError {
    case tokenAcquisitionFailed

    public var errorDescription: String? {
        switch self {
        case .tokenAcquisitionFailed:
            return "Failed to acquire concurrency token"
        }
    }
}

/// Token bucket implementation for rate limiting based on available tokens.
/// Suspends tasks when no tokens are available rather than blocking threads.
actor TokenBucket {
    private var availableTokens: Int
    private var waitingTasks: [(CheckedContinuation<Void, Error>)] = []

    init(tokens: Int) {
        self.availableTokens = tokens
    }

    /// Executes the given work with a token, suspending if none are available.
    /// - Parameter work: The async work to execute once a token is acquired
    /// - Throws: If the task is cancelled while waiting for a token
    func withToken<R: Sendable>(_ work: @Sendable () async throws -> R) async throws -> R {
        // Wait for a token if none available
        if availableTokens == 0 {
            try await waitForToken()
        }

        // Acquire token
        availableTokens -= 1

        // Execute work and release token
        do {
            let result = try await work()
            releaseToken()
            return result
        } catch {
            releaseToken()
            throw error
        }
    }

    private func waitForToken() async throws {
        try await withCheckedThrowingContinuation { continuation in
            waitingTasks.append(continuation)
        }
    }

    private func releaseToken() {
        if !waitingTasks.isEmpty {
            // Resume a waiting task
            let continuation = waitingTasks.removeFirst()
            continuation.resume()
        } else {
            // Return token to pool
            availableTokens += 1
        }
    }
}
