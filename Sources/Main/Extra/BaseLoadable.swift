import OSLog
import SwiftUI

/// Abstract base class for creating custom loadable implementations.
@Observable
@MainActor
open class BaseLoadable<Value: Hashable & Sendable>: Loadable {
    @ObservationIgnored private let log = LoggerFactory.loadingview.logger()

    // MARK: - Loadable
    public var isCanceled = false

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

    public init() {
    }

    open func cancel() {
        log.debug("Canceled BaseLoadable")
        isCanceled = true
    }

    open func reset() {
        isCanceled = false
        stateRelay.update(.idle)
    }

    /// Updates the loading state. Used by subclasses that need custom state updates.
    public func updateState(_ state: LoadingState<Value>) {
        stateRelay.update(state)
    }

    /// Initiates the loading operation, publishing relevant states along the way.
    open func load() async {
        guard !isCanceled else {
            log.debug("Skipping load. isCanceled: \(self.isCanceled)")
            return
        }

        // Prevent re-entrant loads when already loading or loaded
        switch currentState {
        case .loading:
            log.debug("Skipping load. currentState is already .loading")
            return
        case .loaded:
            log.debug("Skipping load. currentState is already .loaded")
            return
        default:
            break
        }

        // Loading at 0% progress.
        // Passing progress info is optional, you may also pass .loading(nil)
        stateRelay.update(.loading(nil))

        do {
            let value = try await fetch()
            guard !isCanceled else {
                return // client cancelled, result no longer needed
            }
            stateRelay.update(.loaded(value))
        } catch {
            guard !isCanceled else {
                return // client cancelled, skip sending an error
            }
            stateRelay.update(.failure(error))
        }
    }

    /// Example of an async fetch operation (simulating a network request).
    open func fetch() async throws -> Value {
        fatalError("Override this method to generate a Value")
    }
}
