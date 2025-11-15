# LoadingView

[![Swift](https://github.com/janodevorg/LoadingView/actions/workflows/swift.yml/badge.svg)](https://github.com/janodevorg/LoadingView/actions/workflows/swift.yml)

A SwiftUI view that emits asynchronous loading states: `.idle`, `.loading`, `.loaded`, and `.failure`.

```swift
@State private var loader = BlockLoadable {
    try await fetchData()
}

var body: some View {
    LoadingView(loader: loader) { value in
        Text("Success loading \(value)")
    }
    .emptyView {
        Text("Nothing here.")
    }
    .errorView { error in
        Text("Error: \(error.localizedDescription)")
    }
    .progressView { progress in
        ProgressView("\(progress.percent)% loaded")
    }
}
```

Use default loading and error views or pass your own. Data is loaded from a type conforming to the Loadable protocol. A few convenient implementations are provided:

- [BlockLoadable](https://github.com/janodevorg/LoadingView/blob/main/Sources/Main/Extra/BlockLoadable.swift): loads data from the closure provided.
- [ConcurrencyLimitingLoadable](https://github.com/janodevorg/LoadingView/blob/main/Sources/Main/Extra/ConcurrencyLimitingLoadable.swift): executes async calls limiting the number of concurrent operations.
- [DebouncingLoadable](https://github.com/janodevorg/LoadingView/blob/main/Sources/Main/Extra/DebouncingLoadable.swift): delays execution until an elapsed time since the last event.
- [RetryableLoader](https://github.com/janodevorg/LoadingView/blob/main/Sources/Main/Extra/RetryableLoader.swift): retry logic and exponential backoff.

Loaders are composable - you can nest them at will to combine behaviors like retry, debounce, and concurrency limiting. Example:
```swift
let searchLoadable = SearchableLoadable()
let debounced = await DebouncingLoadable(
    wrapping: searchLoadable,
    debounceInterval: 0.3
)
let retryable = RetryableLoader(
    base: debounced,
    maxAttempts: 2
)
let finalLoader = ConcurrencyLimitingLoadable(
    wrapping: retryable,
    concurrencyLimit: 1
)
```

Initial loading happens automatically, to prevent it pass `loadOnAppear: false` and call `loader.load()` later:

```swift
LoadingView(loader: loader, loadOnAppear: false) { value in
    ...
}
```

This library uses Swift 6. The v26 branch demonstrates usage of the native Observations framework available in iOS 26+.

## Supported Versions

iOS 26+, macOS 26+, Xcode 16

## Installation

### Using Xcode Swift Package Manager

Using Xcode Swift Package Manager:

1. In Xcode, select **File > Add Packages...**
2. Enter URL: `https://github.com/janodevorg/LoadingView.git`
3. Select the `LoadingView` library and add it to your target.

### Using SPM
```swift
.package(url: "git@github.com:janodevorg/LoadingView.git", from: "1.0.0"),

.product(name: "LoadingView", package: "LoadingView"),
```

## Development

To develop locally clone the repository and initialize submodules:

```bash
git clone https://github.com/janodevorg/LoadingView.git
cd LoadingView
git submodule init
git submodule update
```

## Examples

- [BasicLoadingDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/BasicLoadingDemo/BasicLoadingDemo.swift): default behavior.
- [CancellationDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/CancellationDemo/CancellationDemo.swift): cancelling a loading task.
- [ConcurrencyLimitingDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/ConcurrencyLimitingDemo/ConcurrencyLimitingDemo.swift): executing n operations with a concurrency limit.
- [CustomViewsDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/CustomViewsDemo/CustomViewsDemo.swift): providing custom views for empty, loading, success, and failure state.
- [DebouncedDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/DebouncedDemo/DebouncedDemo.swift): executing an operation when a certain time elapses since a given event.
- [ErrorScenariosDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/ErrorScenariosDemo/ErrorScenariosDemo.swift): different error types and custom error handling views with retry capabilities.
- [ManualLoadingDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/ManualLoadingDemo/ManualLoadingDemo.swift): compares automatic loading on appear versus manual loading triggered by user action.
- [MultipleLoadersDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/MultipleLoadersDemo/MultipleLoadersDemo.swift): demonstrates managing multiple independent loaders within a single view.
- [ProgressTrackingDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/ProgressTrackingDemo/ProgressTrackingDemo.swift): shows real-time progress updates during long-running operations.
- [RetryDemo](https://github.com/janodevorg/LoadingView/blob/main/Demo/Sources/SwiftUI/Demos/RetryDemo/RetryDemo.swift): automatic retry functionality with configurable attempts for handling transient failures.

See them in action in the Demo application.

### Retry on Failure

Wrap any `Loadable` with `RetryableLoader` to automatically handle transient errors.

```swift
import LoadingView
import SwiftUI

// A loader that is designed to fail twice before succeeding
@State private var flakeyLoader = FlakeyLoader(successAfterAttempts: 3)

// Wrap it with RetryableLoader
@State private var retryableLoader = RetryableLoader(
    base: flakeyLoader,
    maxAttempts: 5
)

// Use it in your view
LoadingView(loader: retryableLoader) { message in
    Text(message)
}
```

### Debounced Search

Wrap your search loader with `DebouncingLoadable` to prevent sending a network request on every keystroke.

```swift
import LoadingView
import SwiftUI

// A loader that performs a search
@State private var searchLoader = DebouncedSearchLoader()

// Wrap it with DebouncingLoadable
@State private var debouncedLoader = await DebouncingLoadable(
    wrapping: searchLoader,
    debounceInterval: 0.5 // 500ms
)

// In your view...
TextField("Search...", text: $searchText)
    .onChange(of: searchText) { newValue in
        searchLoader.searchText = newValue
        Task {
            // This load() call is debounced
            await debouncedLoader.load()
        }
    }

LoadingView(loader: debouncedLoader) { results in
    List(results, id: \.self) { Text($0) }
}
```

## Documentation

There are some docs in the [`Docs/`](./Docs) folder.

- **[Documentation.md](./Docs/Documentation.md)**: API reference and usage guide.
- **[DesignDecisions.md](./Docs/DesignDecisions.md)**: how the library changed to overcome several pitfalls.
- **[StateRelay.md](./Docs/StateRelay.md)**: Understand the core component that enables robust state management.
- **[Troubleshooting.md](./Docs/Troubleshooting.md)**: Find solutions to common problems and learn about best practices.
- **[AgentGuide.md](./Docs/AgentGuide.md)**: Complete technical reference optimized for AI agents.

**Tip for AI-assisted development**: If you encounter an issue while using this package with an AI coding agent, provide it with the relevant documentation files above. The docs contain detailed troubleshooting patterns and anti-patterns that help agents quickly identify and fix common problems.
