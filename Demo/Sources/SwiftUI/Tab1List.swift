import LoadingView
import SwiftUI

struct Tab1List: View {
  let loader: RepositoryLoadable<[String], Database>

    var body: some View {
        LoadingView(loader: loader) { items in
            List(items, id: \.self) { item in
                Text(item)
            }
        }
        .navigationTitle("Items")
    }
}
