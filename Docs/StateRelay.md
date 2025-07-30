# StateRelay Implementation

Summary: State management solution that replaces AsyncStream for proper state persistence

## Problem

AsyncStream is designed for event streaming, not state management:
- No replay of last value to new observers
- Single consumption - once exhausted, no more values
- When views navigate away, `.task` cancels and state is lost
- LoadingView returns to `.idle` state even though data exists

## Solution

StateRelay acts as a state holder that broadcasts changes:

```swift
@MainActor
final class StateRelay<Value: Sendable> {
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
    private(set) var currentValue: Value
    
    init(_ initial: Value) {
        self.currentValue = initial
    }
    
    var stream: AsyncStream<Value> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            continuations[id] = continuation
            
            // Key: Immediately replay current value
            continuation.yield(currentValue)
            
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.continuations[id] = nil
                }
            }
        }
    }
    
    func update(_ newValue: Value) {
        currentValue = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }
}
```

## Why "StateRelay"?

The name "StateRelay" comes from reactive programming concepts, particularly from RxSwift/ReactiveX terminology:

1. **Relay** - In RxSwift, a Relay is a special type of subject that:
   - Cannot error out or complete
   - Always has a current value
   - Replays the last value to new subscribers

2. **State** - It's specifically designed to hold and broadcast state changes

The StateRelay in this codebase serves a similar purpose:
- Holds the current state (`currentValue`)
- Broadcasts state changes to multiple observers
- Replays the current value immediately to new observers (preventing the "empty view" bug)
- Cannot fail or complete - it just relays state changes

It's essentially a simplified version of RxSwift's BehaviorRelay, adapted for Swift Concurrency (AsyncStream) instead of RxSwift's Observable pattern.

## Key Features

### 1. State Persistence
- Maintains `currentValue` across observer lifecycle
- State survives view navigation

### 2. Multiple Observers
- Tracks continuations with UUID keys
- Each observer gets independent stream
- All observers receive updates

### 3. Replay on Subscribe
- New observers immediately receive current value
- No "empty state" when returning to view
- Synchronous `currentValue` property available

### 4. Memory Safety
- Weak self in termination handler
- Continuations removed on termination
- Clean deinit handling

## Integration with BaseLoadable

```swift
@Observable
@MainActor
open class BaseLoadable<Value: Hashable & Sendable>: Loadable {
    // State relay that maintains current state and supports multiple observers
    @ObservationIgnored private let stateRelay = StateRelay<LoadingState<Value>>(.idle)
    
    /// The current loading state - can be read synchronously
    public var currentState: LoadingState<Value> {
        stateRelay.currentValue
    }
    
    /// An async sequence of state changes - replays current value to new observers
    public var state: any AsyncSequence<LoadingState<Value>, Never> {
        stateRelay.stream
    }
    
    /// Updates the loading state. Used by subclasses that need custom state updates.
    public func updateState(_ state: LoadingState<Value>) {
        stateRelay.update(state)
    }
}
```

## LoadingView Integration

```swift
.onAppear {
    // Sync with loader's current state
    if let baseLoader = loader as? BaseLoadable<L.Value> {
        let currentState = baseLoader.currentState
        if loadingState != currentState {
            loadingState = currentState
        }
    }
}
```

## Benefits

1. **Navigation Resilience**: State persists when navigating away and back
2. **Multiple Views**: Same loader can be observed by multiple views
3. **Predictable Behavior**: New observers always see current state
4. **No Race Conditions**: State updates are sequential and synchronized
5. **Backwards Compatible**: Same API surface as AsyncStream

## Mental Model

Think of StateRelay as:
- **Store**: Holds current value
- **Broadcaster**: Notifies all observers of changes
- **Replay Subject**: New observers get latest value immediately

Unlike AsyncStream which is:
- **Event Pipe**: One-way flow of events
- **Single Consumer**: First observer gets all values
- **No History**: New observers see only future events

## Current Usage

StateRelay is currently used by:
- **BaseLoadable**: For all state management
- **RetryableLoader**: For state management with retry logic

Still using AsyncStream:
- **DebouncingLoadable**: Uses traditional AsyncStream with continuation