import Foundation

/// State of a loading operation.
public enum LoadingState<Value: Hashable & Sendable>: CustomStringConvertible, Hashable, Sendable {
    /// Initial state indicating no operation is ongoing.
    case idle
    /// A loading operation is in progress.
    case loading(LoadingProgress?)
    /// A loading operation finished with error.
    /// The error is wrapped to provide proper Hashable conformance.
    case failure(HashableError)
    /// A loading operation completed successfully.
    case loaded(Value)

    /// Creates a failure state from any Sendable Error.
    public static func failure(_ error: any Error & Sendable) -> LoadingState {
        .failure(HashableError(error))
    }

    /// Returns the underlying error if this is a failure state.
    public var error: (any Error & Sendable)? {
        if case .failure(let hashableError) = self {
            return hashableError.error
        }
        return nil
    }

    public static func == (lhs: LoadingState<Value>, rhs: LoadingState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case let (.loading(progress1), .loading(progress2)): return progress1 == progress2
        case let (.failure(error1), .failure(error2)): return error1 == error2
        case let (.loaded(value1), .loaded(value2)): return value1 == value2
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .idle:
            hasher.combine(0)
        case .loading(let progress):
            hasher.combine(1)
            hasher.combine(progress)
        case .failure(let hashableError):
            hasher.combine(2)
            hasher.combine(hashableError)
        case .loaded(let value):
            hasher.combine(3)
            hasher.combine(value)
        }
    }

    public var description: String {
        switch self {
        case .idle:
            return ".idle"
        case .loading(let progress):
            return ".loading percent: \(progress?.percent?.description ?? ""), message: \(progress?.message ?? "")"
        case .failure(let hashableError):
            return hashableError.error.localizedDescription
        case .loaded(let value):
            var string = ""
            if let desc = (value as? CustomStringConvertible)?.description {
                string = desc
            } else {
                dump(value, to: &string)
            }
            return ".loaded(\(string))"
        }
    }
}
