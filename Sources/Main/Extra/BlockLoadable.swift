
public final class BlockLoadable<T: Hashable & Sendable>: BaseLoadable<T>, Sendable {
    private let log = LoggerFactory.loadingview.logger()
    private let block: @Sendable() async throws -> T

    public init(block: @Sendable @escaping () async throws -> T,
                file: String = #file,
                function: String = #function) {
        self.block = block
        log.debug("INIT BlockLoadable from \(file).\(function)")
    }
    public override func fetch() async throws -> T {
        try await block()
    }
}
