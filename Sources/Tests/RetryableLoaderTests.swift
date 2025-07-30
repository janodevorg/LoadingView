@testable import LoadingView
import XCTest

enum MockError: Error, Equatable, Sendable {
    case somethingWentWrong
}

// MARK: - MockLoadable: Fails once, then succeeds

/// A simple mock that yields `.failure` on the first `load()`,
/// and `.loaded` on the second and subsequent loads.
@MainActor
final class MockLoadableFailOnce: Loadable {
    typealias Value = Int

    var isCanceled = false
    private let internalStream: AsyncStream<LoadingState<Int>>
    private var continuation: AsyncStream<LoadingState<Int>>.Continuation?
    private(set) var currentState: LoadingState<Int> = .idle

    func cancel() {
        isCanceled = true
    }
    func reset() {
        isCanceled = false
        currentState = .idle
    }

    /// Exposes the read-only side of the stream for `Loadable`.
    var state: any AsyncSequence<LoadingState<Int>, Never>

    private var loadCallCount = 0

    init() {
        var localContinuation: AsyncStream<LoadingState<Int>>.Continuation!
        let stream = AsyncStream<LoadingState<Int>> { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation
        self.internalStream = stream
        self.state = stream

        // When the consumer cancels the stream, mark isCanceled
        self.continuation?.onTermination = { @Sendable _ in
            Task { @MainActor [weak self] in
                self?.isCanceled = true
            }
        }
    }

    func load() async {
        guard let continuation = continuation, !isCanceled else { return }

        loadCallCount += 1
        currentState = .loading(nil)
        continuation.yield(.loading(nil))  // Just a .loading state

        // Fail the first time, succeed on second and thereafter
        if loadCallCount == 1 {
            currentState = .failure(MockError.somethingWentWrong)
            continuation.yield(.failure(MockError.somethingWentWrong))
        } else {
            currentState = .loaded(loadCallCount)
            continuation.yield(.loaded(loadCallCount))
        }
    }
}

// MARK: - MockLoadableAlwaysFail

/// A simple mock that always fails, no matter how many times `load()` is called.
@MainActor
final class MockLoadableAlwaysFail: Loadable {
    typealias Value = Int

    var isCanceled = false
    private let internalStream: AsyncStream<LoadingState<Int>>
    private var continuation: AsyncStream<LoadingState<Int>>.Continuation?
    var state: any AsyncSequence<LoadingState<Int>, Never>
    private(set) var currentState: LoadingState<Int> = .idle

    func cancel() {
        isCanceled = true
    }

    func reset() {
        isCanceled = false
        currentState = .idle
    }

    init() {
        var localContinuation: AsyncStream<LoadingState<Int>>.Continuation!
        let stream = AsyncStream<LoadingState<Int>> { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation
        self.internalStream = stream
        self.state = stream

        self.continuation?.onTermination = { @Sendable _ in
            Task { @MainActor [weak self] in
                self?.isCanceled = true
            }
        }
    }

    func load() async {
        guard let continuation = continuation, !isCanceled else { return }
        currentState = .loading(nil)
        continuation.yield(.loading(nil))
        currentState = .failure(MockError.somethingWentWrong)
        continuation.yield(.failure(MockError.somethingWentWrong))
    }
}

// MARK: - Test suite for RetryableLoader

@MainActor
final class RetryableLoaderTests: XCTestCase {
    /// Gathers AsyncSequence states into an array.
    /// Limit to 10 so it doesn’t hang with infintei sequences
    private func collectStates<S: AsyncSequence>(
        _ sequence: S,
        limit: Int = 10
    ) async throws -> [S.Element] {
        var result = [S.Element]()
        for try await element in sequence.prefix(limit) {
            result.append(element)
        }
        return result
    }

    func testRetryAfterOneFailure_succeedsOnSecondTry() async throws {
        // GIVEN a mock that fails once, then succeeds
        let base = MockLoadableFailOnce()

        // mAke 2 attempts
        let loader = RetryableLoader(wrapping: base, maxAttempts: 2)

        // collect states in the background
        var collectedStates: [LoadingState<Int>] = []
        let statesTask = Task {
            for await state in loader.state {
                collectedStates.append(state)
                // Break after we see success or collected enough states
                if case .loaded = state {
                    break
                }
                // Safety break after collecting many states
                if collectedStates.count > 10 {
                    break
                }
            }
        }

        // WHEN invoking load()
        await loader.load()

        // Give some time for states to be collected and retries to happen
        // RetryableLoader has exponential backoff, so we need to wait longer
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Cancel the collection task
        statesTask.cancel()

        // THEN states should be: .loading, .failure, .loading, .loaded
        // from the arrya I'm just checking for a .loaded(2) because we fail and then we succeed
        guard collectedStates.contains(where: {
            if case .loaded(let value) = $0, value == 2 {
                return true
            }
            return false
        }) else {
            XCTFail("Expected to eventually see .loaded(2)")
            return
        }
    }

    func testExceedMaxAttempts_fails() async throws {
        // GIVEN a mock that always fails
        let base = MockLoadableAlwaysFail()

        // make 2 attempts
        let loader = RetryableLoader(wrapping: base, maxAttempts: 2)

        // Start collecting states
        var collectedStates: [LoadingState<Int>] = []
        let statesTask = Task {
            for await state in loader.state {
                collectedStates.append(state)
                // Break after we see a final failure (no more retries)
                if case .failure = state, collectedStates.count >= 4 {
                    // We expect: .loading, .failure, .loading (retry), .failure (final)
                    break
                }
            }
        }

        // WHEN invoking load()
        await loader.load()

        // Give some time for states to be collected and retries to happen
        // RetryableLoader has exponential backoff, so we need to wait longer
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Cancel the collection task
        statesTask.cancel()

        // THEN it fails after 2 attempts
        guard collectedStates.contains(where: {
            if case .failure(let hashableError) = $0 {
                return (hashableError.error as? MockError) == .somethingWentWrong
            }
            return false
        }) else {
            XCTFail("Expected a .failure(somethingWentWrong)")
            return
        }
    }
}
