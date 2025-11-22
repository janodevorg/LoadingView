# LoadingView Design Decisions for Robustness

This document outlines key design decisions made to prevent common bugs and ensure robust behavior in the LoadingView module.

## 1. AsyncSequence Single-Consumption Protection

**Problem**: AsyncSequence can only be consumed once. If multiple consumers try to iterate the same sequence, only the first gets values.

**Solution in RetryableLoader**:
```swift
private func startMonitoringIfNeeded() {
    guard !hasStartedMonitoring else { return }
    hasStartedMonitoring = true
    
    monitorTask = Task { [weak self] in
        // Create iterator BEFORE any load() calls
        for await state in base.state {
            // Process states...
        }
    }
}

public func load() async {
    // Ensure monitoring is started before the first load
    startMonitoringIfNeeded()
    await base.load()
}
```

**Key Points**:
- Start observing the base loadable's state BEFORE triggering any loads
- Use a flag to ensure monitoring starts only once
- This prevents race conditions where load() might emit states before we're listening

## 2. Continuation Lifecycle Management

**Problem**: AsyncStream continuations can leak memory if not properly finished.

**Solution in DebouncingLoadable** (still uses AsyncStream):
```swift
deinit {
    continuation?.finish()
}
```

**Additional Safety**:
```swift
self.continuation?.onTermination = { @Sendable _ in
    Task { @MainActor [weak self] in
        guard let self else { return }
        self.isCanceled = true
    }
}
```

**Solution in BaseLoadable/RetryableLoader** (Observation-backed):
The Observation framework powers the state AsyncSequence for BaseLoadable, RetryableLoader, and ConcurrencyLimitingLoadable, so there are no manual continuations to finish in those types. For AsyncStream-based helpers (like DebouncingLoadable), keep finishing the continuation in `deinit` as shown above.

**Key Points**:
- Always finish continuations in deinit
- Use weak self in termination handlers to avoid retain cycles
- Guard against nil self to prevent crashes
- Observation removes manual continuation management for the core loaders

## 3. Thread Safety with @MainActor

**Problem**: UI-related code must run on the main thread, but async operations can run on any thread.

**Solution**:
```swift
@MainActor
public final class RetryableLoader<Base: Loadable>: Loadable { ... }

@MainActor
private func errorDetails(_ error: Error) -> String { ... }
```

**Key Points**:
- Mark entire classes as @MainActor when they interact with UI
- Mark individual methods as @MainActor when only specific operations need main thread
- This prevents UI updates from background threads

## 4. State Observation Timing

**Problem**: Starting to observe state changes too early can miss important updates or cause unnecessary work.

**Solution in DebouncingLoadable**:
```swift
private var hasStartedMonitoring = false

private func startMonitoringIfNeeded() {
    guard !hasStartedMonitoring else { return }
    hasStartedMonitoring = true
    
    stateTask = Task { [weak self] in
        for await state in loadable.state {
            currentState = state
            continuation.yield(state)
        }
    }
}

public func load() async {
    startMonitoringIfNeeded()  // Only start when actually loading
    // ... perform load
}
```

**Key Points**:
- Delay state observation until first load() call
- Use a flag to ensure observation starts only once
- This prevents unnecessary resource usage for loadables that might never be used

## 5. Proper Initialization Order

**Problem**: Swift requires calling super.init() in subclasses, but timing matters.

**Solution in BlockLoadable**:
```swift
public init(block: @Sendable @escaping () async throws -> T,
            file: String = #file,
            function: String = #function) {
    self.block = block
    super.init()  // Must come after setting properties
    log.debug("INIT BlockLoadable from \(file).\(function)")
}
```

**Key Points**:
- Set all stored properties before calling super.init()
- This ensures the object is fully initialized before parent class code runs
- BaseLoadable now uses Swift Observations for state streaming, so there's no extra relay object to wire up

## 6. Input Validation

**Problem**: Invalid input can cause unexpected behavior or crashes.

**Solution in LoadingProgress**:
```swift
public init(isCanceled: Bool? = nil, message: String? = nil, percent: Int? = nil) {
    self.isCanceled = isCanceled
    self.message = message
    if let percent {
        self.percent = max(0, min(100, percent))  // Clamp to valid range
    } else {
        self.percent = nil
    }
}
```

**Key Points**:
- Validate and sanitize input at the boundaries
- Use clamping rather than assertions for better resilience
- Document expected ranges in the API

## 7. Avoiding AnyView When Possible

**Problem**: AnyView can hurt SwiftUI performance and type safety.

**Solution**: While LoadingView still uses AnyView for custom views (a reasonable trade-off for API flexibility), we avoid it internally where possible and document the performance implications.

## 8. Retry Attempt Counting

**Problem**: Off-by-one errors in retry logic can confuse users.

**Solution in RetryableLoader**:
```swift
var attemptCount = 1  // Start at 1 for the initial attempt

case .failure where attemptCount < maxAttempts:
    attemptCount += 1
    stateRelay.update(.loading(LoadingProgress(
        message: "Retrying… (attempt \(attemptCount) of \(maxAttempts))"
    )))
```

**Key Points**:
- Start counting at 1 for user-facing messages
- Clear messaging about current attempt vs total attempts
- This matches user expectations (first try is attempt 1, not 0)

## 9. Proper Async Task Cancellation

**Problem**: Tasks that aren't properly cancelled can continue running and waste resources.

**Solution**:
```swift
deinit {
    monitorTask?.cancel()
    debounceTask?.cancel()
    continuation.finish()
}

public func cancel() {
    isCanceled = true
    base.cancel()  // Forward cancellation
    monitorTask?.cancel()
}
```

**Key Points**:
- Cancel all tasks in both deinit and explicit cancel()
- Forward cancellation to wrapped objects
- Check Task.isCancelled in loops

## 10. Preventing Race Conditions

**Problem**: Multiple async operations can interfere with each other.

**Solution**:
- Use atomic flags (hasStartedMonitoring) to ensure operations happen only once
- Capture continuations synchronously during initialization
- Start observation before triggering any state changes
- Use weak self in closures to prevent retain cycles while avoiding crashes

## 11. State Persistence Across Navigation (Observation Streams)

**Problem**: AsyncStream is an event pipe, not a state holder. When views navigate away and return, they can lose state because:
- The `.task` modifier cancels on disappear
- AsyncStream doesn't replay values to new observers
- LoadingView's local `@State` resets to `.idle`

**Solution with Observation**:
```swift
public var state: any AsyncSequence<LoadingState<Value>, Never> {
    Observations { self.currentState }
}
```

**LoadingView State Synchronization**:
```swift
.onAppear {
    // Sync with loader's current state if we lost track
    let currentState = loader.currentState
    if loadingState != currentState {
        loadingState = currentState
    }
}
```

**Key Points**:
- Observation-backed AsyncSequences support multiple observers and replay the latest value
- DebouncingLoadable still uses traditional AsyncStream with a single continuation
- State persists across view lifecycle
- Synchronous `currentState` property provides immediate reads
- Prevents the "empty view after navigation" bug

## 12. Protocol-Oriented State Synchronization

**Problem**: LoadingView's onAppear needed to cast to BaseLoadable to access currentState, breaking protocol abstraction.

**Solution**: Added currentState property to the Loadable protocol:
```swift
@MainActor
public protocol Loadable {
    // ... existing properties
    var currentState: LoadingState<Value> { get }
}
```

**Key Points**:
- All Loadable implementations must provide currentState
- Removes type cast in LoadingView: `loader.currentState` instead of `(loader as? BaseLoadable)?.currentState`
- Maintains protocol-oriented design
- Enables state sync for all implementations, not just BaseLoadable subclasses

## 13. Proper Error Hashing with HashableError

**Problem**: LoadingState's Hashable conformance treated all errors as identical, violating the hash/equality contract and causing issues with Sets/Dictionaries.

**Solution**: Introduced HashableError wrapper that provides unique identity for each error:
```swift
public struct HashableError: Hashable, Sendable {
    public let error: Error
    private let id = UUID()
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// LoadingState now uses:
case failure(HashableError)

// With convenience factory method:
public static func failure(_ error: Error) -> LoadingState {
    .failure(HashableError(error))
}
```

**Key Points**:
- Each error instance gets a unique identity via UUID
- Respects Hashable/Equatable contract - different errors have different hashes
- Maintains backward compatibility through static factory method
- Enables proper use of LoadingState in Sets, Dictionaries, and switch statements
- The wrapped error remains accessible via `.error` property

## 14. Requiring Sendable Errors for Swift 6 Concurrency

**Problem**: LoadingState.failure(Error) wasn't fully Sendable because Error protocol doesn't conform to Sendable, potentially causing data race issues in Swift 6.

**Solution**: Changed error requirements to be explicitly Sendable:
```swift
// HashableError now requires Sendable errors
public struct HashableError: Hashable, Sendable {
    public let error: any Error & Sendable
    private let id = UUID()
}

// Factory method requires Sendable
public static func failure(_ error: any Error & Sendable) -> LoadingState

// Error views receive Sendable errors
public func errorView(@ViewBuilder _ view: @escaping (any Error & Sendable) -> any View)
```

**Key Points**:
- Aligns with Swift 6 strict concurrency requirements
- Prevents data races when LoadingState crosses actor boundaries
- Forward-looking change that prepares for Swift's concurrency evolution
- All custom errors must now conform to Sendable (usually just adding the conformance)
- Foundation errors like NSError are already Sendable

## Summary

These design decisions work together to create a robust, predictable API that:
- Prevents common concurrency bugs and data races
- Manages resources properly
- Provides clear error messages
- Fails gracefully rather than crashing
- Works correctly with Swift's modern concurrency model
- Maintains state across view lifecycle events
- Adheres to protocol-oriented programming principles
- Prepares for Swift 6's strict concurrency checking

The key theme is defensive programming: assume things can go wrong and design to handle those cases gracefully.
