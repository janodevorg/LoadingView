import LoadingView
import SwiftUI

struct ControlSection: View {
    let userLoader: BlockLoadable<User>
    let statsLoader: BlockLoadable<Stats>
    let activityLoader: BlockLoadable<[String]>

    var body: some View {
        VStack(spacing: 20) {
            // Control buttons
            HStack(spacing: 20) {
                Button("Reload All") {
                    Task {
                        // Start all loaders concurrently
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask {
                                await userLoader.reset()
                                await userLoader.load()
                            }
                            group.addTask {
                                await statsLoader.reset()
                                await statsLoader.load()
                            }
                            group.addTask {
                                await activityLoader.reset()
                                await activityLoader.load()
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset All") {
                    userLoader.reset()
                    statsLoader.reset()
                    activityLoader.reset()
                }
                .buttonStyle(.bordered)
            }

            // Status indicator
            VStack(spacing: 10) {
                Text("Loading States")
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack(spacing: 20) {
                    LoadingIndicator(title: "User", loader: userLoader)
                    LoadingIndicator(title: "Stats", loader: statsLoader)
                    LoadingIndicator(title: "Activity", loader: activityLoader)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}