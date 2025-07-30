import SwiftUI

struct FruitListView: View {
    let fruits: [String]

    var body: some View {
        List(fruits, id: \.self) { fruit in
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text(fruit)
            }
        }
    }
}