import Foundation

public protocol Repository: Sendable {
    associatedtype Data
    func fetchData() async throws -> Data
}

public actor Database: Repository {
    private let log = LoggerFactory.loadingview.logger()
    public typealias Data = [String]

    private var items = ["Item 1", "Item 2"]

    init() {
        log.debug("INIT Database")
    }

    public func fetchData() async throws -> [String] {
        try await Task.sleep(nanoseconds: 500_000_000) // simulate latency
        return items
    }

    public func addItem(_ item: String) async {
        items.append(item)
        log.debug("items.count \(self.items.count)")
    }
}
