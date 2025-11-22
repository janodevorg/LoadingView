import Foundation
import LoadingView

@MainActor
class FlakeyLoader: BaseLoadable<String> {
    private var totalAttemptCount = 0  // Total attempts across all retries
    private let successAfterAttempts: Int

    init(successAfterAttempts: Int = 3) {
        self.successAfterAttempts = successAfterAttempts
        super.init()
    }

    override func reset() {
        print("🔄 FlakeyLoader: Reset called - resetting attempt count")
        super.reset()
        totalAttemptCount = 0
    }

    func hardReset() {
        print("🔄 FlakeyLoader: Hard reset called")
        reset()
    }

    override func fetch() async throws -> String {
        totalAttemptCount += 1
        print("🌐 FlakeyLoader: Fetch attempt #\(totalAttemptCount) (will succeed after \(successAfterAttempts) attempts)")

        // Simulate network delay
        print("  - Sleeping for 1 second...")
        try await Task.sleep(nanoseconds: 1_000_000_000)

        if totalAttemptCount < successAfterAttempts {
            print("  - ❌ Throwing network error (attempt \(totalAttemptCount) < \(successAfterAttempts))")
            throw DemoError.networkError
        }

        let message = "Finally connected after \(totalAttemptCount) attempts!"
        print("  - Success: \(message)")
        return message
    }
}
