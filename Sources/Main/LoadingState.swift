import Foundation

public struct LoadingProgress: Hashable, Sendable {
    public let isCanceled: Bool?
    public let message: String?
    public let percent: Int? // 0 to 100
    public init(isCanceled: Bool? = nil, message: String? = nil, percent: Int? = nil) {
        self.isCanceled = isCanceled
        self.message = message
        self.percent = percent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isCanceled)
        hasher.combine(message)
        hasher.combine(percent)
    }
}

/// State of a loading operation.
public enum LoadingState<Value: Hashable & Sendable>: CustomStringConvertible, Hashable, Sendable {
    /// Initial state indicating no operation is ongoing.
    case idle
    /// A loading operation is in progress.
    case loading(LoadingProgress?)
    /// A loading operation finished with error.
    case failure(Error)
    /// A loading operation completed successfully.
    case loaded(Value)

    /// This equatable implementation disregards associated values for error and `Value`.
    public static func == (lhs: LoadingState<Value>, rhs: LoadingState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case let (.loading(progress1), .loading(progress2)): return progress1 == progress2
        case (.failure, .failure): return true
        case let  (.loaded(value1), .loaded(value2)): return value1 == value2
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
        case .failure:
            // all failures are considered equal
            hasher.combine(2)
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
        case .failure(let error):
            return error.localizedDescription
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
