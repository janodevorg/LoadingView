import Foundation

/// Protocol for objects that load values asynchronously and publish loading states.
///
/// Conforming types must provide:
/// - An async sequence of `LoadingState` changes
/// - Cancellation support
/// - State reset functionality
/// - Async loading implementation
///
/// Example implementation:
/// ```swift
/// class DataLoader: Loadable {
///     typealias Value = [String]
///
///     var state: any AsyncSequence<LoadingState<[String]>, Never> {
///         stateStream
///     }
///
///     func load() async {
///         // Emit loading state
///         // Perform async work
///         // Emit loaded or failure state
///     }
/// }
/// ```
@MainActor
public protocol Loadable {
    /// The type of value that will be loaded.
    associatedtype Value: Hashable, Sendable

    /// An asynchronous sequence that publishes the loading state of the `Value`.
    var state: any AsyncSequence<LoadingState<Value>, Never> { get }

    /// The current loading state. Used for state synchronization when views reappear.
    var currentState: LoadingState<Value> { get }

    /// Flag indicating if the loading operation has been cancelled.
    var isCanceled: Bool { get }

    /// Cancels the ongoing loading operation, if any.
    func cancel()

    /// Resets the loadable to its initial state, setting the `isCanceled` flag to `false`.
    func reset()

    /// Initiates the loading of `Value`.
    ///
    /// Typically, you will first send a `.loading` state through the `state` publisher, then
    /// attempt to load the `Value` and publish either a `.loaded(value)` on success
    /// or a `.failure(error)` on failure.
    func load() async
}
