
import Observation
import OSLog
import SwiftUI

/// Abstract base class for creating custom loadable implementations.
/// Uses iOS 26+ native Observations framework.
@Observable
@MainActor
open class BaseLoadable<Value: Hashable & Sendable>: Loadable {
    @ObservationIgnored private let log = LoggerFactory.loadingview.logger()

    // MARK: - Loadable
    public var isCanceled = false

    /// The current loading state - directly observable
    public var currentState: LoadingState<Value> = .idle

    /// An async sequence of state changes using native Observations
    public var state: any AsyncSequence<LoadingState<Value>, Never> {
        Observations {
            self.currentState
        }
    }

    public init() {
    }

    open func cancel() {
        log.debug("Canceled BaseLoadable")
        isCanceled = true
    }

    open func reset() {
        isCanceled = false
        currentState = .idle
    }

    /// Updates the loading state. Used by subclasses that need custom state updates.
    public func updateState(_ state: LoadingState<Value>) {
        currentState = state
    }

    /// Initiates the loading operation, publishing relevant states along the way.
    open func load() async {
        guard !isCanceled else {
            log.debug("Skipping load. isCanceled: \(self.isCanceled)")
            return
        }

        // Loading at 0% progress.
        // Passing progress info is optional, you may also pass .loading(nil)
        currentState = .loading(nil)

        do {
            let value = try await fetch()
            guard !isCanceled else {
                return // client cancelled, result no longer needed
            }
            log.debug("Yielded state: \(String(describing: value))")
            currentState = .loaded(value)
        } catch {
            guard !isCanceled else {
                return // client cancelled, skip sending an error
            }
            currentState = .failure(error)
        }
    }

    /// Example of an async fetch operation (simulating a network request).
    open func fetch() async throws -> Value {
        fatalError("Override this method to generate a Value")
    }
}
