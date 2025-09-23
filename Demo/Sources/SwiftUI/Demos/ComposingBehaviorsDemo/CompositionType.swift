import Foundation

/// Defines the available composition patterns for combining different Loadable behaviors.
enum CompositionType: String, CaseIterable {
    case retryWithDebounce = "Debounce + Retry"
    case concurrencyWithRetry = "Retry + Concurrency"
    case fullStack = "Full Stack (All 3)"
    case debounceWithConcurrency = "Concurrency + Debounce"

    var description: String {
        switch self {
        case .retryWithDebounce:
            return "Search with debouncing (0.5s) and retry on failure (3 attempts)"
        case .concurrencyWithRetry:
            return "API calls with concurrency limit (2) and retry (3 attempts)"
        case .fullStack:
            return "Search with all behaviors: debounce (0.3s), retry (2), concurrency (1)"
        case .debounceWithConcurrency:
            return "Search with concurrency limit (3) and debouncing (0.7s)"
        }
    }

    var requiresSearchInput: Bool {
        switch self {
        case .retryWithDebounce, .fullStack, .debounceWithConcurrency:
            return true
        case .concurrencyWithRetry:
            return false
        }
    }

    var compositionOrder: [String] {
        switch self {
        case .retryWithDebounce:
            return ["Base Loader", "DebouncingLoadable", "RetryableLoader"]
        case .concurrencyWithRetry:
            return ["Base Loader", "RetryableLoader", "ConcurrencyLimitingLoadable"]
        case .fullStack:
            return ["Base Loader", "DebouncingLoadable", "RetryableLoader", "ConcurrencyLimitingLoadable"]
        case .debounceWithConcurrency:
            return ["Base Loader", "ConcurrencyLimitingLoadable", "DebouncingLoadable"]
        }
    }

    var icon: String {
        switch self {
        case .retryWithDebounce:
            return "arrow.clockwise.circle"
        case .concurrencyWithRetry:
            return "square.3.layers.3d"
        case .fullStack:
            return "square.stack.3d.up"
        case .debounceWithConcurrency:
            return "timer"
        }
    }
}
