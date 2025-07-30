import Foundation

/// A relay that holds current state and broadcasts changes to multiple observers.
///
/// Unlike AsyncStream, StateRelay:
/// - Replays the current value to new observers immediately
/// - Supports multiple concurrent observers
/// - Maintains state between observer connections
@MainActor
final class StateRelay<Value: Sendable> {
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
    private(set) var currentValue: Value

    init(_ initial: Value) {
        self.currentValue = initial
    }

    /// An async stream that immediately yields the current value to new observers.
    var stream: AsyncStream<Value> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = UUID()
            continuations[id] = continuation

            // Immediately replay current value to new observer
            continuation.yield(currentValue)

            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.continuations[id] = nil
                }
            }
        }
    }

    /// Updates the value and notifies all observers.
    func update(_ newValue: Value) {
        currentValue = newValue
        for continuation in continuations.values {
            continuation.yield(newValue)
        }
    }

    deinit {
        for continuation in continuations.values {
            continuation.finish()
        }
    }
}
