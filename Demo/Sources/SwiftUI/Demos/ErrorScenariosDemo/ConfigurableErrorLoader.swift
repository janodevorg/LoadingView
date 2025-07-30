import Foundation
import LoadingView

@MainActor
class ConfigurableErrorLoader: BaseLoadable<String> {
    var errorToThrow: Error = DemoError.networkError

    override func fetch() async throws -> String {
        // Simulate loading time
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw errorToThrow
    }
}