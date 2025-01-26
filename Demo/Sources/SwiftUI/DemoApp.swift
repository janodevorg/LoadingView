import SwiftUI

@main
struct DemoApp: App {
    let repository = Database()

    var body: some Scene {
        WindowGroup {
            TabsView(repository: repository)
        }
    }
}
