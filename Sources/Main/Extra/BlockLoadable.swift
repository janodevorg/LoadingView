import Observation

/// A loadable implementation that executes an async closure.
///
/// BlockLoadable provides the simplest way to create a loadable object by wrapping
/// an async closure. However, it emits loading states with `nil` progress, which
/// means the default LoadingView won't display a progress indicator unless you
/// explicitly add a `.progressView` modifier.
///
/// For loading operations that need to show progress, either:
/// - Add `.progressView { _ in ... }` to your LoadingView
/// - Create a custom BaseLoadable subclass that emits LoadingProgress
///
/// Example:
/// ```swift
/// @State private var loader = BlockLoadable {
///     try await fetchData()
/// }
///
/// LoadingView(loader: loader) { data in
///     DataView(data)
/// }
/// .progressView { _ in
///     ProgressView()  // Required to see loading indicator
/// }
/// ```
public final class BlockLoadable<T: Hashable & Sendable>: BaseLoadable<T> {
    @ObservationIgnored private let log = LoggerFactory.loadingview.logger()
    private let block: @Sendable() async throws -> T

    public init(block: @Sendable @escaping () async throws -> T,
                file: String = #file,
                function: String = #function) {
        self.block = block
        super.init()
        log.debug("INIT BlockLoadable from \(file).\(function)")
    }
    public override func fetch() async throws -> T {
        try await block()
    }
}
