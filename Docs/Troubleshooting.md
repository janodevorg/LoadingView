# LoadingView Troubleshooting Guide

This guide covers common issues encountered when using LoadingView and their solutions, based on real-world usage patterns.

## Table of Contents
- [Common Issues](#common-issues)
- [Patterns & Anti-Patterns](#patterns--anti-patterns)
- [Platform-Specific Issues](#platform-specific-issues)
- [State Management Best Practices](#state-management-best-practices)

## Common Issues

### 1. Success State Not Rendering

**Symptom**: Logs show success state reached but UI doesn't update
```
State: SUCCESS - Finally connected after 3 attempts!
// But no success view renders
```

**Cause**: Multiple observers competing for values from a single AsyncStream. AsyncStream is single-consumer - each value goes to only ONE observer.

**Solution**: Publish state via Swift's Observation framework instead of a raw AsyncStream when you need multiple observers.
```swift
// WRONG: AsyncStream with multiple observers
private let continuation: AsyncStream<LoadingState<Value>>.Continuation
public private(set) var state: any AsyncSequence<LoadingState<Value>, Never>

// CORRECT: Observation-backed stream that replays the latest value
public var state: any AsyncSequence<LoadingState<Value>, Never> {
    Observations { self.currentState }
}
```
*Note*: DebouncingLoadable still uses AsyncStream internally; keep only one consumer or wrap it in a BaseLoadable if you need broadcast-style observation.

### 2. Infinite Cancel Loops

**Symptom**: Repeated cancel logs after pressing cancel
```
Canceled BaseLoadable
Changing state to: .loading percent: , message: Cancelled
Canceled BaseLoadable
Changing state to: .loading percent: , message: Cancelled
// Repeats indefinitely
```

**Cause**: LoadingView automatically calls `loader.cancel()` when it sees `progress.isCanceled == true`. If your `cancel()` override updates state with `isCanceled = true`, it creates an infinite loop.

**Solution**: Guard against redundant cancellation
```swift
override func cancel() {
    // Prevent infinite loop
    guard !isCanceled else { return }
    
    super.cancel()
    updateState(.loading(LoadingProgress(
        isCanceled: true,
        message: "Cancelled"
    )))
}
```

### 3. Retry Counter Not Resetting

**Symptom**: After successful retry, starting again continues from previous attempt count
```
// First run: attempt 1, 2, 3 ✓
// Second run: attempt 4, 5 ✗ (should be 1, 2)
```

**Cause**: Internal state not properly reset between retry sessions

**Solution**: Reset monitoring state in RetryableLoader
```swift
public func reset() {
    isCanceled = false
    base.reset()
    currentState = .idle
    
    // Reset monitoring task to start fresh
    monitorTask?.cancel()
    monitorTask = nil
    hasStartedMonitoring = false
}
```

### 4. Debounced Loading Shows Count of 1 After Reset

**Symptom**: Reset button should show 0/0 but shows 1/1

**Cause**: Text field change from "value" to "" triggers onTextChange during reset

**Solution**: Use a flag to prevent counting during reset
```swift
@State private var isResetting = false

onTextChange: { newValue in
    if !isResetting {
        callCount += 1
        // ... rest of logic
    }
}

onReset: {
    isResetting = true
    // ... reset logic
    Task {
        try? await Task.sleep(nanoseconds: 100_000_000)
        isResetting = false
    }
}
```

### 5. Error Scenarios Not Updating

**Symptom**: Selecting different error types doesn't update the displayed error

**Cause**: Creating new BlockLoadable instances doesn't trigger SwiftUI updates reliably

**Solution**: Use a configurable loader that maintains the same instance
```swift
// Single configurable instance
@MainActor
class ConfigurableErrorLoader: BaseLoadable<String> {
    var errorToThrow: Error = DemoError.networkError
    
    override func fetch() async throws -> String {
        throw errorToThrow
    }
}

// Update configuration instead of creating new instance
loader.errorToThrow = selectedError.error
loader.reset()
await loader.load()
```

### 6. Body Not Rendering - Loader Reassignment in .task

**Symptom**: LoadingView shows empty/idle state and never displays loaded content, even though data loads successfully

**Cause**: Reassigning the loader variable inside `.task` creates a new `BlockLoadable` instance, but LoadingView continues observing the old instance that was passed during initialization.

**Solution**: Create a custom `BaseLoadable` subclass that maintains the same instance

```swift
// ANTI-PATTERN: Reassigning loader in .task
@State private var loader = BlockLoadable<Bool> { true }

var body: some View {
    LoadingView(loader: loader) { value in
        Text("Success")
    }
    .task {
        // This creates a NEW instance - LoadingView still observes the OLD one
        loader = BlockLoadable {
            await doWork()
            return true
        }
        await loader.load()
    }
}

// PATTERN: Use a custom loader that maintains instance identity
@MainActor
final class DataLoader: BaseLoadable<Bool> {
    private weak var viewModel: ViewModel?

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func fetch() async throws -> Bool {
        guard let viewModel else {
            throw LoaderError.viewModelDeallocated
        }
        await viewModel.loadData()
        return true
    }
}

// In your view:
@State private var viewModel = ViewModel()
@State private var loader: DataLoader

init() {
    let vm = ViewModel()
    self._viewModel = State(initialValue: vm)
    self._loader = State(initialValue: DataLoader(viewModel: vm))
}

var body: some View {
    LoadingView(loader: loader) { value in
        Text("Success")
    }
    .task {
        await loader.load()  // No reassignment needed
    }
}
```

**Key Points**:
- LoadingView captures the loader reference during initialization
- Reassigning the `@State` variable doesn't update LoadingView's internal reference
- Use dependency injection to configure loaders, not reassignment
- This is the same underlying issue as #5, but occurs during initialization

### 7. Multiple Windows Opening on macOS

**Symptom**: Multiple LoadingView windows open on app launch (e.g., 4 identical windows)
```
LoadingView: load()
Dependencies loading
Initializing database...
// Repeated 4 times
```

**Cause**: Using `@State` with an `@Observable` loader in the `App` struct can cause unexpected behavior during app initialization. While `@State` + `@Observable` works fine in regular Views, the `App` struct has different lifecycle semantics that can trigger multiple window creations.

**Solution**: Use plain `let` for `@Observable` objects in your `App` struct
```swift
// PROBLEMATIC: @State in App struct with immediate initialization
@main
struct MyApp: App {
    @State private var loadable = MyLoadable()  // Can cause issues in App struct
    
    var body: some Scene {
        WindowGroup {
            LoadingView(loader: loadable) { /* ... */ }
        }
    }
}

// CORRECT: Plain property in App struct
@main  
struct MyApp: App {
    private let loadable = MyLoadable()  // Clear single instance
    
    var body: some Scene {
        WindowGroup {
            LoadingView(loader: loadable) { /* ... */ }
        }
    }
}
```

**Why this happens**:
- The `App` struct's body may be evaluated multiple times during startup
- `WindowGroup` with `@State` initialization can confuse SwiftUI's scene management
- This is specific to the `App` struct - `@State` + `@Observable` works fine in regular Views

**Additional Considerations**:
- macOS may also restore multiple windows from previous sessions. Add an AppDelegate to disable restoration:
```swift
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldRestoreApplicationState(_ app: NSApplication, coder: NSCoder) -> Bool {
        false  // Disable window restoration
    }
}
```

**Note**: This issue is specific to the `App` struct context. Using `@State` with `@Observable` objects in regular Views is generally fine and follows normal SwiftUI patterns.

## Patterns & Anti-Patterns

### AsyncStream Usage

```swift
// ANTI-PATTERN: Sharing AsyncStream between multiple consumers
.task { for await state in loader.state { /* UI updates */ } }
.task { for await state in loader.state { /* Logging */ } }  // Steals states!

// PATTERN: Use Observation-backed state streams so each observer sees the same values
public var state: any AsyncSequence<LoadingState<Value>, Never> {
    Observations { self.currentState }
}
```

### Loader Lifecycle Management

```swift
// ANTI-PATTERN: Reset base loader during retries
case .failure(_) where attemptCount < maxAttempts:
    base.reset()  // Resets internal state like attempt counters!
    await base.load()

// PATTERN: Only reset when starting fresh
case .failure(_) where attemptCount < maxAttempts:
    // Don't reset - just retry
    await base.load()
```

### State Updates in Loaders

```swift
// ANTI-PATTERN: Creating new instances to trigger updates
loader = BlockLoadable { /* new logic */ }  // SwiftUI might not detect change

// PATTERN: Update existing instance state
loader.configuration = newValue
loader.reset()
await loader.load()
```

### Loader Initialization and Reassignment

```swift
// ANTI-PATTERN: Reassigning in .task block
@State private var loader = BlockLoadable<Bool> { true }

var body: some View {
    LoadingView(loader: loader) { ... }
        .task {
            loader = BlockLoadable { /* work */ }  // LoadingView still observes old instance!
            await loader.load()
        }
}

// PATTERN: Use custom loader with dependency injection
@State private var loader: CustomLoader

init() {
    let loader = CustomLoader(dependencies: ...)
    self._loader = State(initialValue: loader)
}

var body: some View {
    LoadingView(loader: loader) { ... }
        .task {
            await loader.load()  // No reassignment needed
        }
}
```

### Cancellation Handling

```swift
// ANTI-PATTERN: Simple property override
open var isCanceled = false  // Can't override stored properties

// PATTERN: Make methods overridable
open func cancel() {
    isCanceled = true
}
```

## Platform-Specific Issues

### iOS: Black Bars / Letterboxing

**Symptom**: iOS app displays with black bars at top and bottom

**Cause**: Missing UILaunchScreen configuration - iOS runs app in compatibility mode

**Solution for Tuist Projects**:
```swift
.target(
    name: "Demo-iOS",
    infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [
            "UIColorName": "AccentColor",
            "UIImageName": ""
        ]
    ]),
    // ... rest of configuration
)
```

**Solution for Standard Xcode Projects**: Add to Info.plist:
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>AccentColor</string>
    <key>UIImageName</key>
    <string></string>
</dict>
```

## State Management Best Practices

### 1. Single Source of Truth
- Use one loader instance per data source
- Update configuration rather than creating new instances
- Reset state appropriately based on user actions

### 2. Proper Reset Timing
```swift
// User-initiated fresh start: Full reset
onStartNewOperation: {
    loader.reset()
    await loader.load()
}

// Retry within same operation: No reset
onRetry: {
    // Don't reset - preserve attempt counts, etc.
    await loader.load()
}
```

### 3. Observable State Updates
- Always use `updateState()` for state changes in BaseLoadable subclasses
- Don't rely on computed properties alone - update backing state
- For collections, use copy-then-replace pattern

### 4. Cancellation Best Practices
- Override `cancel()` when you need to update UI state
- Always call `super.cancel()` to maintain base functionality
- Guard against redundant operations
- Avoid state updates that trigger more cancellations

### 5. Multi-Observer Scenarios
If you need multiple parts of your app to observe the same loader:
1. Prefer the Observation-backed loaders (BaseLoadable, RetryableLoader, ConcurrencyLimitingLoadable)
2. Each observer gets the latest state immediately
3. Observation manages replay and lifecycle for you
4. If you need multi-observer support for an AsyncStream-based loader (like DebouncingLoadable), wrap it in a BaseLoadable facade

## Debug Tips

### Enable Logging
The library uses OSLog. Filter by subsystem "loadingview" to see internal state changes.

### Common Log Patterns to Watch For
- Multiple "INIT BlockLoadable" - May indicate unintended recreations
- "Syncing state on appear" - LoadingView detecting state mismatch
- Repeated identical state changes - Possible infinite loop

### State Verification
```swift
// Add to your loader for debugging
override func updateState(_ state: LoadingState<Value>) {
    print("🔄 State transition: \(currentState) → \(state)")
    super.updateState(state)
}
```

## Quick Reference

| Issue | Likely Cause | Quick Fix |
|-------|-------------|-----------|
| Success not showing | Multiple AsyncStream observers | Use Observation-backed loaders |
| Infinite cancel loop | cancel() updating isCanceled state | Add guard in cancel() |
| Wrong retry count | Not resetting internal state | Reset monitoring task |
| State not updating | Creating new instances | Update existing instance |
| Debounce count wrong | onChange during reset | Use isResetting flag |
| Body not rendering | Reassigning loader in .task | Use custom BaseLoadable subclass |

## Getting Help

If you encounter issues not covered here:
1. Check loader state transitions with logging
2. Verify single vs multiple observers
3. Ensure proper reset/lifecycle management
4. File an issue with minimal reproduction case
