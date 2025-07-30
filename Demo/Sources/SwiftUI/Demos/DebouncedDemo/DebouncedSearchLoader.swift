import Foundation
import LoadingView

@MainActor
@Observable
class DebouncedSearchLoader: BaseLoadable<[String]> {
    var actualCallCount = 0
    var searchText = ""

    override func reset() {
        super.reset()
        // Don't reset actualCallCount here - it should be managed externally
        // to track total API calls across multiple resets
    }

    override func fetch() async throws -> [String] {
        actualCallCount += 1

        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)

        let allFruits = [
            "Apple", "Apricot", "Avocado",
            "Banana", "Blackberry", "Blueberry",
            "Cherry", "Coconut", "Cranberry",
            "Date", "Dragon fruit",
            "Elderberry",
            "Fig",
            "Grape", "Grapefruit", "Guava"
        ]

        if searchText.isEmpty {
            return []
        }

        return allFruits.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
}