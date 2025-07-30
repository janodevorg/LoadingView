import Foundation

/// Progress information for a loading operation.
public struct LoadingProgress: Hashable, Sendable {
    public let isCanceled: Bool?
    public let message: String?
    public let percent: Int? // 0 to 100
    public init(isCanceled: Bool? = nil, message: String? = nil, percent: Int? = nil) {
        self.isCanceled = isCanceled
        self.message = message
        if let percent {
            self.percent = max(0, min(100, percent))
        } else {
            self.percent = nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isCanceled)
        hasher.combine(message)
        hasher.combine(percent)
    }
}
