import OSLog
import SwiftUI

@Observable
@MainActor
open class BaseLoadable<Value: Hashable & Sendable>: Loadable {
    @ObservationIgnored private let log = LoggerFactory.loadingview.logger()

    // MARK: - Loadable
    public var isCanceled = false
    public var state: any AsyncSequence<LoadingState<Value>, Never>

    // `state` implementation
    @ObservationIgnored private let internalStream: AsyncStream<LoadingState<Value>>

    // continuation of the internalStream, where we’ll be yielding states
    @ObservationIgnored private var continuation: AsyncStream<LoadingState<Value>>.Continuation?

    public init() {
        var localContinuation: AsyncStream<LoadingState<Value>>.Continuation!
        let stream = AsyncStream<LoadingState<Value>> { continuation in
            localContinuation = continuation
        }
        self.internalStream = stream
        self.continuation = localContinuation
        self.state = stream
            // Add here any transformation from AsyncAlgorithms, e.g.
            // .debounce(for: .seconds(0.5))

        self.continuation?.onTermination = { @Sendable _ /* termination */ in
            Task { @MainActor [weak self] in
                self?.isCanceled = true
            }
        }
        log.debug("INIT BaseLoadable")
    }

    public func cancel() {
        log.debug("Canceled BaseLoadable")
        isCanceled = true
    }

    public func reset() {
        isCanceled = false
    }

    /// Initiates the loading operation, publishing relevant states along the way.
    open func load() async {
        guard let continuation, !isCanceled else {
            log.debug("Skipping load. isCanceled: \(self.isCanceled). continuation: \(String(describing: self.continuation))")
            return
        }

        // Loading at 0% progress.
        // Passing progress info is optional, you may also pass .loading(nil)
        continuation.yield(.loading(nil))

        do {
            let value = try await fetch()
            guard !isCanceled else {
                return // client cancelled, result no longer needed
            }
            log.debug("Yielded state: \(String(describing: value))")
            continuation.yield(.loaded(value))
        } catch {
            guard !isCanceled else {
                return // client cancelled, skip sending an error
            }
            continuation.yield(.failure(error))
        }
    }

    /// Example of an async fetch operation (simulating a network request).
    open func fetch() async throws -> Value {
        fatalError("Override this method to generate a Value")
    }
}
