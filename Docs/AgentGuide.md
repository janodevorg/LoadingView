# LoadingView Library Guide for Agents

Summary: Complete technical reference for using the LoadingView SwiftUI library

## Overview

LoadingView is a SwiftUI component that manages asynchronous loading states. It observes `Loadable` objects and automatically renders UI for idle, loading, success, and error states.

## Core Components

### LoadingView

Generic SwiftUI view that renders different states:
```swift
LoadingView(loader: someLoader) { value in
    // Success content
}
```

States rendered:
- `.idle`: Initial state
- `.loading(progress)`: Active loading with optional progress
- `.loaded(value)`: Success with data
- `.failure(error)`: Error state

### Loadable Protocol

Requirements for conforming types:
```swift
@MainActor
protocol Loadable {
    associatedtype Value: Hashable & Sendable
    var state: any AsyncSequence<LoadingState<Value>, Never> { get }
    var currentState: LoadingState<Value> { get }
    var isCanceled: Bool { get }
    func load() async
    func reset()
    func cancel()
}
```

### LoadingState Enum

```swift
enum LoadingState<Value> {
    case idle
    case loading(LoadingProgress?)
    case loaded(Value)
    case failure(Error)
}
```

### LoadingProgress

```swift
struct LoadingProgress {
    let isCanceled: Bool?
    let message: String?
    let percent: Int? // 0-100, auto-clamped
}
```

## Provided Implementations

### BlockLoadable

Simple async closure wrapper:
```swift
@State private var loader = BlockLoadable<String> {
    try await fetchData()
    return "Result"
}
```

> [!NOTE]
> BlockLoadable emits `.loading(nil)`. Add `.progressView { _ in ... }` to show loading indicator.

### BaseLoadable

Abstract class for custom loaders:
```swift
class CustomLoader: BaseLoadable<Data> {
    override func fetch() async throws -> Data {
        // Update progress
        updateState(.loading(LoadingProgress(percent: 50)))
        // Perform work
        return data
    }
}
```

Features:
- `@Observable` for SwiftUI integration
- Observation-backed state stream for multiple observers
- `currentState` for synchronous access
- `updateState(_:)` for progress updates

### DebouncingLoadable

Delays execution until time elapses:
```swift
let debounced = await DebouncingLoadable(
    wrapping: baseLoader,
    debounceInterval: 0.5,
    executeFirstImmediately: false
)
```

### RetryableLoader

Automatic retry with exponential backoff:
```swift
let retryable = RetryableLoader(
    base: loader,
    maxAttempts: 3
)
```

### ConcurrencyLimitingLoadable

Limits concurrent operations:
```swift
let limited = ConcurrencyLimitingLoadable(
    wrapping: loader,
    concurrencyLimit: 3
)
```

Uses token bucket pattern, maintains FIFO order.

## View Modifiers

### Custom State Views

```swift
LoadingView(loader: loader) { data in
    Text(data)
}
.emptyView {
    Text("No data")
}
.progressView { progress in
    ProgressView()
    if let percent = progress?.percent {
        Text("\(percent)%")
    }
}
.errorView { error in
    VStack {
        Text(error.localizedDescription)
        Button("Retry") {
            Task { await loader.load() }
        }
    }
}
```

## Usage Patterns

### Basic Loading

```swift
@State private var loader = BlockLoadable {
    return try await fetchData()
}

var body: some View {
    LoadingView(loader: loader) { data in
        Text(data)
    }
    .progressView { _ in
        ProgressView()
    }
}
```

### Manual Loading

```swift
LoadingView(loader: loader, loadOnAppear: false) { data in
    Text(data)
}

Button("Load") {
    Task { await loader.load() }
}
```

### Progress Tracking

```swift
class ProgressLoader: BaseLoadable<String> {
    override func fetch() async throws -> String {
        for i in 0...100 {
            updateState(.loading(LoadingProgress(
                percent: i,
                message: "Processing..."
            )))
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        return "Complete"
    }
}
```

### Composing Behaviors

```swift
// Stack multiple behaviors
let searchLoader = SearchableLoadable()
let debounced = await DebouncingLoadable(
    wrapping: searchLoader,
    debounceInterval: 0.3
)
let retryable = RetryableLoader(
    base: debounced,
    maxAttempts: 2
)
let final = ConcurrencyLimitingLoadable(
    wrapping: retryable,
    concurrencyLimit: 1
)
```

## Key Behaviors

### Default Progress View
- Hidden when `progress == nil`
- Shows when `.progressView` modifier added
- Displays percent, message, cancellation status

### Loading Lifecycle
- `loadOnAppear: true`: Auto-loads on appear
- `loadOnAppear: false`: Manual load required
- Multiple `load()` calls ignored during active loading
- State persists across navigation

### State Management
- Uses Swift Observation to broadcast to multiple observers
- New observers immediately see the latest state
- Thread-safe with `@MainActor` isolation
- No stream exhaustion issues for Observation-backed loaders

### Error Handling
- Errors wrapped in `HashableError` for `Hashable` conformance
- Access error via `state.error` property
- Custom error views via `.errorView` modifier

## Platform Requirements

- iOS 26+
- macOS 26+
- Swift 6
- Xcode 16

## Installation

### Swift Package Manager
```swift
.package(url: "git@github.com:janodevorg/LoadingView.git", from: "1.0.0")
...
.package(product: "LoadingView")
```

### Xcode
1. File > Add Packages...
2. Enter: `https://github.com/janodev/LoadingView.git`
3. Add LoadingView to target

## Common Tasks

### Handle Network Errors
```swift
.errorView { error in
    if (error as NSError).code == NSURLErrorNotConnectedToInternet {
        Text("No internet connection")
    } else {
        Text("Error: \(error.localizedDescription)")
    }
}
```

### Cancel on Disappear
```swift
.onDisappear {
    loader.cancel()
}
```

### Refresh Data
```swift
Button("Refresh") {
    Task {
        loader.reset()
        await loader.load()
    }
}
```

### Track Multiple Loaders
```swift
@State private var userLoader = BlockLoadable { ... }
@State private var postsLoader = BlockLoadable { ... }

VStack {
    LoadingView(loader: userLoader) { user in
        Text(user.name)
    }
    LoadingView(loader: postsLoader) { posts in
        List(posts) { post in
            Text(post.title)
        }
    }
}
```

## Troubleshooting

### Empty View After Navigation
- LoadingView syncs with `currentState` on appear
- Observation-backed streams replay the latest state to new observers
- No need to reload after navigation

### Progress Not Showing
- BlockLoadable emits `nil` progress
- Add `.progressView { _ in ... }` modifier
- Or use BaseLoadable with `updateState()`

### Multiple Load Calls
- Load ignored if already loading
- Check `currentState` before calling
- Use `reset()` to force reload

## Code Locations

- Main components: `/Sources/Main/`
- Implementations: `/Sources/Main/Extra/`
- Examples: `/Demo/Sources/SwiftUI/Demos/`
- Tests: `/Sources/Tests/`
