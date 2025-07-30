import LoadingView
import SwiftUI

struct LoadingIndicator<T: Hashable & Sendable>: View {
    let title: String
    let loader: BlockLoadable<T>
    @State private var currentState: LoadingState<T> = .idle

    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.caption2)
        }
        .task {
            for await state in loader.state {
                currentState = state
            }
        }
    }

    var indicatorColor: Color {
        switch currentState {
        case .idle:
            return .gray
        case .loading:
            return .orange
        case .loaded:
            return .green
        case .failure:
            return .red
        }
    }
}