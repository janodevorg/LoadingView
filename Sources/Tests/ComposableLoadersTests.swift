import Testing
import Foundation
@testable import LoadingView

/// Tests demonstrating composition of different Loadable behaviors
@Suite("Composable Loaders", .serialized)
struct ComposableLoadersTests {

    // MARK: - Test Loaders

    @MainActor
    final class TestLoadable: BaseLoadable<String> {
        var fetchCount = 0
        var failUntilAttempt = 0
        var delay: TimeInterval = 0.1
        var value = "Success"

        override func fetch() async throws -> String {
            fetchCount += 1

            if delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            if fetchCount <= failUntilAttempt {
                throw TestError.intentionalFailure
            }

            return "\(value) - Attempt \(fetchCount)"
        }

        override func reset() {
            super.reset()
            fetchCount = 0
        }
    }

    enum TestError: Error, LocalizedError {
        case intentionalFailure

        var errorDescription: String? {
            "Intentional test failure"
        }
    }

    // MARK: - Retry + Debounce Tests

    @Test("Retry wrapping Debounce - retries debounced failures") @MainActor
    func testRetryWithDebounce() async throws {
        let base = TestLoadable()
        base.failUntilAttempt = 2 // Fail first 2 attempts
        base.delay = 0.05

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.1
        )

        let retryable = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 3
        )

        // First load should succeed after retries
        await retryable.load()

        // Wait for state to stabilize (needs time for 3 retry attempts with exponential backoff)
        // Attempt 1: immediate fail, Attempt 2: after 1s delay, Attempt 3: after 2s delay
        // Plus execution time for each attempt (~0.05s * 3 + debounce 0.1s)
        try await Task.sleep(nanoseconds: 4_000_000_000)

        let finalState = retryable.currentState
        guard case .loaded(let value) = finalState else {
            Issue.record("Expected loaded state, got \(finalState)")
            return
        }

        #expect(value.contains("Success"))
        #expect(value.contains("Attempt 3"))
        #expect(base.fetchCount == 3)
    }

    @Test("Debounce behavior preserved when wrapped by Retry") @MainActor
    func testDebouncePreservedInComposition() async throws {
        let base = TestLoadable()
        base.delay = 0.05

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.2
        )

        let retryable = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 3
        )

        // Rapid fire multiple loads
        await retryable.load()
        await retryable.load()
        await retryable.load()

        // Wait for debounce period
        try await Task.sleep(nanoseconds: 300_000_000)

        // Should only have executed once due to debouncing
        #expect(base.fetchCount == 1)
    }

    // MARK: - Concurrency + Retry Tests

    @Test("Concurrency limiting with retry - respects concurrency limit") @MainActor
    func testConcurrencyWithRetry() async throws {
        let base = TestLoadable()
        base.delay = 0.1
        base.failUntilAttempt = 1

        let retryable = RetryableLoader(
            wrapping: base,
            maxAttempts: 2
        )

        let limited = ConcurrencyLimitingLoadable(
            wrapping: retryable,
            concurrencyLimit: 1
        )

        // Start multiple concurrent loads
        async let load1: Void = limited.load()
        async let load2: Void = limited.load()
        async let load3: Void = limited.load()

        _ = await (load1, load2, load3)

        // Wait for all to complete
        try await Task.sleep(nanoseconds: 500_000_000)

        // Due to concurrency limit of 1, loads should be sequential
        // Each load fails once then succeeds, so 2 attempts per load
        // But multiple load() calls on same loadable are ignored while loading
        #expect(base.fetchCount >= 2) // At least one full retry cycle
    }

    // MARK: - Full Stack Tests

    @Test("Full stack composition - all behaviors work together") @MainActor
    func testFullStackComposition() async throws {
        let base = TestLoadable()
        base.delay = 0.05
        base.failUntilAttempt = 1

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.1
        )

        let retryable = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 2
        )

        let limited = ConcurrencyLimitingLoadable(
            wrapping: retryable,
            concurrencyLimit: 2
        )

        // Multiple rapid loads
        await limited.load()
        await limited.load()
        await limited.load()

        // Wait for completion
        try await Task.sleep(nanoseconds: 600_000_000)

        // Wait longer for debounce + retry cycles
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let finalState = limited.currentState
        guard case .loaded(let value) = finalState else {
            Issue.record("Expected loaded state, got \(finalState)")
            return
        }

        #expect(value.contains("Success"))
        // Debouncing should have reduced multiple calls to fewer executions
        #expect(base.fetchCount <= 3)
    }

    // MARK: - Debounce + Concurrency Tests

    @Test("Debounce wrapping Concurrency - maintains both behaviors") @MainActor
    func testDebounceWithConcurrency() async throws {
        let base1 = TestLoadable()
        base1.value = "Task1"
        base1.delay = 0.2

        let base2 = TestLoadable()
        base2.value = "Task2"
        base2.delay = 0.2

        let limited1 = ConcurrencyLimitingLoadable(
            wrapping: base1,
            concurrencyLimit: 1
        )

        let limited2 = ConcurrencyLimitingLoadable(
            wrapping: base2,
            concurrencyLimit: 1
        )

        let debounced1 = await DebouncingLoadable(
            wrapping: limited1,
            debounceInterval: 0.1
        )

        let debounced2 = await DebouncingLoadable(
            wrapping: limited2,
            debounceInterval: 0.1
        )

        // Rapid fire on both
        await debounced1.load()
        await debounced1.load()
        await debounced2.load()
        await debounced2.load()

        // Wait for completion
        try await Task.sleep(nanoseconds: 400_000_000)

        // Each should have only executed once due to debouncing
        #expect(base1.fetchCount == 1)
        #expect(base2.fetchCount == 1)
    }

    // MARK: - State Propagation Tests

    @Test("State propagates through composition layers") @MainActor
    func testStatePropagation() async throws {
        let base = TestLoadable()
        base.delay = 0.1

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.05
        )

        let retryable = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 3
        )

        // Monitor state changes
        var states: [LoadingState<String>] = []
        let stateTask = Task {
            for await state in retryable.state {
                states.append(state)
                if case .loaded = state { break }
            }
        }

        await retryable.load()

        // Wait for completion
        try await Task.sleep(nanoseconds: 600_000_000)
        stateTask.cancel()

        // Should have progressed through states
        #expect(states.count >= 2) // At least idle -> loading -> loaded

        // Verify final state
        guard case .loaded(let value) = states.last else {
            Issue.record("Expected final state to be loaded")
            return
        }
        #expect(value.contains("Success"))
    }

    // MARK: - Error Handling Tests

    @Test("Errors propagate correctly through composition") @MainActor
    func testErrorPropagation() async throws {
        let base = TestLoadable()
        base.failUntilAttempt = 999 // Always fail

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.05
        )

        let retryable = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 2
        )

        await retryable.load()

        // Wait for retries to complete (2 attempts with exponential backoff)
        // Attempt 1: immediate fail, Attempt 2: 1s delay = ~1s total
        try await Task.sleep(nanoseconds: 2_000_000_000)

        let finalState = retryable.currentState
        guard case .failure = finalState else {
            Issue.record("Expected failure state, got \(finalState)")
            return
        }

        // Error is wrapped in HashableError
        #expect(base.fetchCount == 2) // Should have tried twice
    }

    // MARK: - Cancellation Tests

    @Test("Cancellation works through composition layers") @MainActor
    func testCancellationPropagation() async throws {
        let base = TestLoadable()
        base.delay = 1.0 // Long delay

        let retryable = RetryableLoader(
            wrapping: base,
            maxAttempts: 3
        )

        let limited = ConcurrencyLimitingLoadable(
            wrapping: retryable,
            concurrencyLimit: 1
        )

        // Start loading
        Task {
            await limited.load()
        }

        // Wait a bit then cancel
        try await Task.sleep(nanoseconds: 100_000_000)
        limited.cancel()

        #expect(limited.isCanceled)
        #expect(retryable.isCanceled)
        #expect(base.isCanceled)
    }

    // MARK: - Reset Behavior Tests

    @Test("Reset propagates through all layers") @MainActor
    func testResetPropagation() async throws {
        let base = TestLoadable()

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.05
        )

        let retryable = RetryableLoader(
            wrapping: debounced,
            maxAttempts: 3
        )

        // Load and complete
        await retryable.load()
        try await Task.sleep(nanoseconds: 200_000_000)

        // Reset
        retryable.reset()

        // All should be in idle state
        #expect(retryable.currentState == .idle)
        #expect(base.currentState == .idle)
        // fetchCount gets reset to 0
        #expect(base.fetchCount == 0)
    }
}

// MARK: - Performance Tests

@Suite("Composition Performance", .serialized)
struct CompositionPerformanceTests {

    @Test("Composition doesn't create excessive overhead") @MainActor
    func testCompositionOverhead() async throws {
        let base = ComposableLoadersTests.TestLoadable()
        base.delay = 0.01

        let startDirect = ContinuousClock.now
        await base.load()
        let directDuration = (ContinuousClock.now - startDirect)

        base.reset()

        // Create composed stack
        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.001
        )
        let retryable = RetryableLoader(wrapping: debounced, maxAttempts: 1)
        let limited = ConcurrencyLimitingLoadable(wrapping: retryable, concurrencyLimit: 10)

        let startComposed = ContinuousClock.now
        await limited.load()
        let composedDuration = (ContinuousClock.now - startComposed)

        // Composed shouldn't be more than 2x slower
        let overhead = composedDuration / directDuration
        #expect(overhead < 2.0)
    }
}

// MARK: - Edge Cases

@Suite("Composition Edge Cases", .serialized)
struct CompositionEdgeCaseTests {

    @Test("Empty state handling through composition") @MainActor
    func testEmptyStatePropagation() async throws {
        @MainActor
        final class EmptyLoadable: BaseLoadable<[String]> {
            override func fetch() async throws -> [String] {
                [] // Return empty array
            }
        }

        let base = EmptyLoadable()
        let retryable = RetryableLoader(wrapping: base, maxAttempts: 3)

        await retryable.load()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard case .loaded(let value) = retryable.currentState else {
            Issue.record("Expected loaded state, got \(retryable.currentState)")
            return
        }

        #expect(value.isEmpty)
    }

    @Test("Rapid reset and load cycles") @MainActor
    func testRapidResetLoad() async throws {
        let base = ComposableLoadersTests.TestLoadable()
        base.delay = 0.05

        let debounced = await DebouncingLoadable(
            wrapping: base,
            debounceInterval: 0.1
        )

        // Rapid reset/load cycles
        for _ in 0..<5 {
            debounced.reset()
            await debounced.load()
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        // Should handle gracefully without crashes
        try await Task.sleep(nanoseconds: 200_000_000)

        // Should have completed at least one load
        #expect(base.fetchCount >= 1)
    }
}
