import Foundation

/// Wrapper that makes any Error hashable by using a unique identifier.
/// This ensures proper Hashable/Equatable semantics for LoadingState.
public struct HashableError: Hashable, Sendable {
    public let error: any Error & Sendable
    private let id = UUID()

    public init(_ error: any Error & Sendable) {
        self.error = error
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
