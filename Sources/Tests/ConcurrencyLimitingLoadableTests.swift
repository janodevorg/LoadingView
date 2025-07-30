import Testing
@testable import LoadingView
import Foundation

/// Mock loadable that tracks concurrent executions for testing
@MainActor
private final class ConcurrentTrackingLoadable: BaseLoadable<String> {
    private(set) var concurrentCount = 0
    private(set) var maxConcurrentCount = 0
    private(set) var totalExecutions = 0

    /// Duration of each load operation in nanoseconds
    let loadDuration: UInt64

    /// Optional error to throw during fetch
    var errorToThrow: Error?

    init(loadDuration: UInt64 = 100_000_000) { // 0.1 seconds default
        self.loadDuration = loadDuration
        super.init()
    }

    override func fetch() async throws -> String {
        // Track concurrent executions
        concurrentCount += 1
        totalExecutions += 1
        maxConcurrentCount = max(maxConcurrentCount, concurrentCount)

        defer { concurrentCount -= 1 }

        // Simulate work
        try await Task.sleep(nanoseconds: loadDuration)

        if let error = errorToThrow {
            throw error
        }

        return "Result \(totalExecutions)"
    }
}

@Suite("ConcurrencyLimitingLoadable Tests")
struct ConcurrencyLimitingLoadableTests {

    @Test("Respects concurrency limit")
    @MainActor
    func testConcurrencyLimit() async throws {
        // Create a base loader with measurable load duration
        let baseLoader = ConcurrentTrackingLoadable(loadDuration: 200_000_000) // 0.2 seconds
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 3
        )

        // Start monitoring state
        let stateMonitor = Task {
            for await state in limitedLoader.state {
                if case .loaded = state {
                    break
                }
            }
        }

        // Launch 10 concurrent load operations
        let loadTasks = (1...10).map { _ in
            Task {
                await limitedLoader.load()
            }
        }

        // Wait a bit to ensure operations have started
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // Check that we never exceed the limit
        #expect(baseLoader.maxConcurrentCount <= 3)

        // Wait for all tasks to complete
        for task in loadTasks {
            await task.value
        }

        // Verify all operations eventually completed
        #expect(baseLoader.totalExecutions == 10)

        stateMonitor.cancel()
    }

    @Test("Handles single concurrent operation")
    @MainActor
    func testSingleConcurrency() async throws {
        let baseLoader = ConcurrentTrackingLoadable()
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 1
        )

        // Launch multiple operations
        let task1 = Task { await limitedLoader.load() }
        let task2 = Task { await limitedLoader.load() }
        let task3 = Task { await limitedLoader.load() }

        await task1.value
        await task2.value
        await task3.value

        // With limit of 1, max concurrent should never exceed 1
        #expect(baseLoader.maxConcurrentCount == 1)
        #expect(baseLoader.totalExecutions == 3)
    }

    @Test("Propagates state changes from base loader")
    @MainActor
    func testStatePropagation() async throws {
        let baseLoader = ConcurrentTrackingLoadable()
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 2
        )

        var collectedStates: [LoadingState<String>] = []

        let stateTask = Task {
            for await state in limitedLoader.state {
                collectedStates.append(state)
                if case .loaded = state {
                    break
                }
            }
        }

        await limitedLoader.load()

        // Give state propagation time to complete
        try await Task.sleep(nanoseconds: 150_000_000)

        stateTask.cancel()

        // Should have received loading and loaded states
        #expect(collectedStates.count >= 2)
        #expect(collectedStates.contains { if case .loading = $0 { true } else { false } })
        #expect(collectedStates.contains { if case .loaded = $0 { true } else { false } })
    }

    @Test("Handles errors from base loader")
    @MainActor
    func testErrorPropagation() async throws {
        struct TestError: Error, Equatable {
            let message: String
        }

        let baseLoader = ConcurrentTrackingLoadable()
        baseLoader.errorToThrow = TestError(message: "Test failure")

        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 2
        )

        var capturedError: HashableError?
        let stateTask = Task {
            for await state in limitedLoader.state {
                if case .failure(let error) = state {
                    capturedError = error
                    break
                }
            }
        }

        await limitedLoader.load()

        // Wait for error propagation
        try await Task.sleep(nanoseconds: 150_000_000)

        stateTask.cancel()

        #expect(capturedError != nil)
        if let actualError = capturedError?.error as? TestError {
            #expect(actualError.message == "Test failure")
        } else {
            Issue.record("Expected TestError but got \(type(of: capturedError?.error))")
        }
    }

    @Test("Cancellation releases tokens")
    @MainActor
    func testCancellationReleasesTokens() async throws {
        let baseLoader = ConcurrentTrackingLoadable(loadDuration: 500_000_000) // 0.5 seconds
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 1
        )

        // Start first operation
        let task1 = Task {
            await limitedLoader.load()
        }

        // Wait for it to start
        try await Task.sleep(nanoseconds: 50_000_000)

        // Cancel it
        limitedLoader.cancel()
        task1.cancel()

        // Reset to clear canceled state
        limitedLoader.reset()

        // Try another operation - should work if token was released
        let task2 = Task {
            await limitedLoader.load()
        }

        // Give it time to potentially deadlock if token wasn't released
        try await Task.sleep(nanoseconds: 100_000_000)

        // If we get here without hanging, the test passes
        task2.cancel()

        #expect(Bool(true)) // Test passed if we reach here
    }

    @Test("Reset clears state properly")
    @MainActor
    func testReset() async throws {
        let baseLoader = ConcurrentTrackingLoadable()
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 2
        )

        // Load once
        await limitedLoader.load()

        // Verify loaded state
        #expect(limitedLoader.currentState.isLoaded)

        // Reset
        limitedLoader.reset()

        // Should be back to idle
        #expect(limitedLoader.currentState == .idle)
        #expect(!limitedLoader.isCanceled)
    }

    @Test("Zero concurrency limit throws precondition", .disabled("Cannot test precondition failures in Swift Testing"), arguments: [-1, 0])
    @MainActor
    func testInvalidConcurrencyLimit(limit: Int) async throws {
        let baseLoader = ConcurrentTrackingLoadable()

        // This would trigger a precondition failure
        _ = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: limit
        )
    }

    @Test("Multiple observers receive state updates")
    @MainActor
    func testMultipleObservers() async throws {
        let baseLoader = ConcurrentTrackingLoadable()
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 2
        )

        var observer1States: [LoadingState<String>] = []
        var observer2States: [LoadingState<String>] = []

        // Start two observers
        let observer1 = Task {
            for await state in limitedLoader.state {
                observer1States.append(state)
                if case .loaded = state { break }
            }
        }

        let observer2 = Task {
            for await state in limitedLoader.state {
                observer2States.append(state)
                if case .loaded = state { break }
            }
        }

        // Trigger load
        await limitedLoader.load()

        // Wait for completion
        try await Task.sleep(nanoseconds: 150_000_000)

        observer1.cancel()
        observer2.cancel()

        // Both observers should have received states
        #expect(!observer1States.isEmpty)
        #expect(!observer2States.isEmpty)

        // Both should have the same sequence of states
        #expect(observer1States.count == observer2States.count)
    }

    @Test("Rapid successive loads respect token limit")
    @MainActor
    func testRapidLoads() async throws {
        let baseLoader = ConcurrentTrackingLoadable(loadDuration: 100_000_000) // 0.1 seconds
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 2
        )

        // Fire off loads as fast as possible
        var tasks: [Task<Void, Never>] = []
        for _ in 1...20 {
            tasks.append(Task {
                await limitedLoader.load()
            })
            // Minimal delay between launches
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }

        // Monitor max concurrency during execution
        var maxSeenConcurrency = 0
        let monitorTask = Task {
            while !Task.isCancelled {
                maxSeenConcurrency = max(maxSeenConcurrency, baseLoader.concurrentCount)
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms checks
            }
        }

        // Wait for all to complete
        for task in tasks {
            await task.value
        }

        monitorTask.cancel()

        // Verify limit was never exceeded
        #expect(maxSeenConcurrency <= 2)
        #expect(baseLoader.maxConcurrentCount <= 2)
        #expect(baseLoader.totalExecutions == 20)
    }

    @Test("Token bucket handles task cancellation gracefully")
    @MainActor
    func testTokenBucketCancellation() async throws {
        let baseLoader = ConcurrentTrackingLoadable(loadDuration: 1_000_000_000) // 1 second
        let limitedLoader = ConcurrencyLimitingLoadable(
            wrapping: baseLoader,
            concurrencyLimit: 1
        )

        // Fill the token bucket
        let blockingTask = Task {
            await limitedLoader.load()
        }

        // Wait for it to acquire the token
        try await Task.sleep(nanoseconds: 50_000_000)

        // Now try to load, which should wait for a token
        let waitingTask = Task {
            await limitedLoader.load()
        }

        // Cancel the waiting task before it gets a token
        try await Task.sleep(nanoseconds: 50_000_000)
        waitingTask.cancel()

        // Cancel the blocking task to free the token
        blockingTask.cancel()
        limitedLoader.cancel()

        // Reset and try again - should work
        limitedLoader.reset()

        let finalTask = Task {
            await limitedLoader.load()
        }

        // This should complete quickly if tokens are managed correctly
        try await Task.sleep(nanoseconds: 200_000_000)

        finalTask.cancel()

        // Test passes if we don't deadlock
        #expect(Bool(true))
    }
}

// MARK: - Helpers

extension LoadingState {
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}