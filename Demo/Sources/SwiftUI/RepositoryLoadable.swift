import Foundation
import LoadingView
import OSLog

@MainActor
public final class RepositoryLoadable
<T: Hashable & Sendable, R: Repository>: BaseLoadable<T>, Sendable where R.Data == T {

    private let log = LoggerFactory.loadingview.logger()
    private let repository: R

    public init(repository: R,
                file: String = #file,
                function: String = #function) {
        self.repository = repository
        log.debug("INIT RepositoryLoadable from \(file).\(function)")
    }

    public override func fetch() async throws -> T {
        log.debug("RepositoryLoadable.fetch() - Starting") // Added
         let value = try await Task.detached {
             try await self.repository.fetchData()
         }.value
         log.debug("RepositoryLoadable.fetch() - Finished, value: \(String(describing: value))") // Added
         return value
    }
}
