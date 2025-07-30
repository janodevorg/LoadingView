# LoadingView

Summary: SwiftUI component for managing and displaying asynchronous loading states

## Overview

LoadingView observes `Loadable` objects and renders different UI states:
- `.idle`: Initial state before loading
- `.loading(progress)`: Active loading with optional progress
- `.loaded(value)`: Success state with data
- `.failure(error)`: Error state

## Core Components

### LoadingView

Generic view that renders loading states:
```swift
LoadingView(loader: someLoader) { value in
    // Success content
}
```

### Loadable Protocol

Requirements:
- `associatedtype Value: Hashable & Sendable`
- `var state: any AsyncSequence<LoadingState<Value>, Never> { get }`
- `var currentState: LoadingState<Value> { get }`
- `var isCanceled: Bool { get }`
- `func load() async`
- `func reset()`
- `func cancel()`

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
    let percent: Int? // 0 to 100, automatically clamped
}
```

## Implementations

### BlockLoadable

Simple async closure wrapper that emits loading states with `nil` progress:
```swift
BlockLoadable<String> {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    return "Result"
}
```

**Note**: BlockLoadable emits `.loading(nil)`, which means the default LoadingView won't display a progress indicator. To see a loading indicator, you must add `.progressView { _ in ... }` to your LoadingView.

### BaseLoadable

Abstract class for custom loaders:
- Override `fetch() async throws -> Value`
- Handles state management via StateRelay
- Supports cancellation
- Provides `currentState: LoadingState<Value>` for synchronous access
- Provides `updateState(_:)` for custom state updates
- Marked with `@Observable` for SwiftUI integration

### DebouncingLoadable

Wraps another loadable with debounce:
```swift
await DebouncingLoadable(
    wrapping: baseLoader,
    debounceInterval: 0.5,
    executeFirstImmediately: false
)
```

**Note**: DebouncingLoadable still uses AsyncStream internally for state management.

### RetryableLoader

Adds retry logic to any loadable:
```swift
RetryableLoader(
    base: loader,
    maxAttempts: 3
)
```

Uses StateRelay for state management and provides exponential backoff between retry attempts.

### ConcurrencyLimitingLoadable

Limits the number of concurrent load operations using a token bucket pattern:
```swift
ConcurrencyLimitingLoadable(
    wrapping: baseLoader,
    concurrencyLimit: 3
)
```

Features:
- Suspends tasks when limit reached (doesn't block threads)
- Maintains order of requests (FIFO queue)
- Integrates with Swift's priority system
- Uses StateRelay for state management

Useful for:
- Rate limiting API calls
- Preventing server overload
- Managing resource-intensive operations
- Controlling parallel downloads/uploads

## View Modifiers

### .emptyView

Custom view for `.idle` state:
```swift
.emptyView {
    Text("No data")
}
```

### .progressView

Custom view for `.loading` state:
```swift
.progressView { progress in
    VStack {
        ProgressView()
        if let message = progress?.message {
            Text(message)
        }
    }
}
```

**Note**: Adding `.progressView` enables rendering even when progress is nil

### .errorView

Custom view for `.failure` state:
```swift
.errorView { error in
    Text("Error: \(error.localizedDescription)")
}
```

## Default Behaviors

### Progress View Visibility

- Default progress view hidden when `progress == nil`
- Adding `.progressView` modifier shows progress always
- Default view includes: ProgressView(), percent, message, cancellation status

### Load Timing

- `loadOnAppear: true` (default): Loads automatically
- `loadOnAppear: false`: Manual load required

### State Transitions

- Multiple `load()` calls ignored during active loading
- `reset()` updates state to `.idle`
- Cancellation triggered when `progress.isCanceled == true`
- State persists across view navigation via StateRelay

## Usage Patterns

### Basic Loading

```swift
@State private var loader = BlockLoadable {
    // Async work
    return data
}

LoadingView(loader: loader) { data in
    // Display data
}
.progressView { _ in
    ProgressView() // Required for BlockLoadable to show loading indicator
}
```

### Manual Loading

```swift
LoadingView(loader: loader, loadOnAppear: false) { data in
    // Display data
}

Button("Load") {
    Task {
        await loader.load()
    }
}
```

### Progress Tracking

```swift
class CustomLoader: BaseLoadable<Data> {
    override func fetch() async throws -> Data {
        updateState(.loading(
            LoadingProgress(message: "Step 1", percent: 25)
        ))
        // Work...
        return data
    }
}
```

### Error Handling

```swift
.errorView { error in
    VStack {
        Text(error.localizedDescription)
        Button("Retry") {
            Task {
                loader.reset()
                await loader.load()
            }
        }
    }
}
```

### Concurrency Limiting

```swift
// Limit concurrent network requests
class BatchImageLoader: BaseLoadable<[UIImage]> {
    let imageURLs: [URL]
    
    init(urls: [URL]) {
        self.imageURLs = urls
        super.init()
    }
    
    override func fetch() async throws -> [UIImage] {
        // Download images with concurrency limit
        try await withThrowingTaskGroup(of: UIImage.self) { group in
            for url in imageURLs {
                group.addTask {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    return UIImage(data: data)!
                }
            }
            
            var images: [UIImage] = []
            for try await image in group {
                images.append(image)
            }
            return images
        }
    }
}

// Wrap with concurrency limiting
let batchLoader = BatchImageLoader(urls: imageURLs)
let limitedLoader = ConcurrencyLimitingLoadable(
    wrapping: batchLoader,
    concurrencyLimit: 3  // Only 3 downloads at a time
)

LoadingView(loader: limitedLoader) { images in
    // Display images
}
```

## Implementation Details

### State Management (StateRelay)

- BaseLoadable uses StateRelay instead of raw AsyncStream
- StateRelay maintains current state and broadcasts to multiple observers
- New observers immediately receive current state (prevents empty views)
- LoadingView syncs with loader's current state on `.onAppear`

### AsyncStream Management

- StateRelay wraps AsyncStream with replay functionality
- LoadingView subscribes via `.task` modifier
- State updates trigger SwiftUI redraws
- Supports multiple concurrent observers

### Memory Management

- Use `[weak self]` in async contexts
- Cancel operations on view disappear if needed
- StateRelay handles continuation cleanup
- No stream exhaustion issues

### Thread Safety

- All UI updates on `@MainActor`
- Loadable implementations must be `Sendable`
- State transitions are sequential
- StateRelay is `@MainActor` isolated

### Navigation Resilience

- State persists when navigating away and back
- LoadingView syncs with loader's `currentState` on appear
- No need to reload data after navigation
- Prevents "empty view" bug after returning to a view