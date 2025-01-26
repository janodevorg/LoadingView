import SwiftUI

struct TabsView: View {
    private let log = LoggerFactory.loadingview.logger()
    private let repository: Database
    @State private var loader: RepositoryLoadable<[String], Database>

    init(repository: Database) {
        self.repository = repository
        _loader = State(initialValue: RepositoryLoadable(repository: repository))
        log.debug("INIT TabsView")
    }

    var body: some View {
        TabView {
            NavigationStack { Tab1List(loader: loader) }
                .tabItem { Label("Items", systemImage: "list.bullet") }

            NavigationStack { Tab2Add(database: repository) }
                .tabItem { Label("Add", systemImage: "plus") }
        }
    }
}
