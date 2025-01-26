import SwiftUI

struct Tab2Add: View {
    let database: Database
    @State private var newItem = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("New item", text: $newItem)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Add Item") {
                Task {
                    // add new item
                    await database.addItem(newItem)
                    newItem = ""
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Add Item")
    }
}
