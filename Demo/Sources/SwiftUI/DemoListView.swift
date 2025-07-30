import SwiftUI

struct DemoListView: View {
    struct Demo: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let destination: AnyView
    }

    let demos = [
        Demo(
            title: "Basic LoadingView",
            description: "Simple loading with default views",
            icon: "circle.fill",
            destination: AnyView(BasicLoadingDemo())
        ),
        Demo(
            title: "Custom Views",
            description: "Custom empty, progress, and error views",
            icon: "paintbrush.fill",
            destination: AnyView(CustomViewsDemo())
        ),
        Demo(
            title: "Progress Tracking",
            description: "Loading with percentage and messages",
            icon: "percent",
            destination: AnyView(ProgressTrackingDemo())
        ),
        Demo(
            title: "Retry on Failure",
            description: "Automatic retry with exponential backoff",
            icon: "arrow.clockwise",
            destination: AnyView(RetryDemo())
        ),
        Demo(
            title: "Debounced Loading",
            description: "Prevent rapid repeated loads",
            icon: "timer",
            destination: AnyView(DebouncedDemo())
        ),
        Demo(
            title: "Manual Loading",
            description: "Control when loading starts",
            icon: "hand.tap.fill",
            destination: AnyView(ManualLoadingDemo())
        ),
        Demo(
            title: "Cancellation",
            description: "Cancel ongoing operations",
            icon: "xmark.circle.fill",
            destination: AnyView(CancellationDemo())
        ),
        Demo(
            title: "Error Scenarios",
            description: "Different error types and handling",
            icon: "exclamationmark.triangle.fill",
            destination: AnyView(ErrorScenariosDemo())
        ),
        Demo(
            title: "Multiple Loaders",
            description: "Coordinate multiple loading operations",
            icon: "square.stack.3d.up.fill",
            destination: AnyView(MultipleLoadersDemo())
        ),
        Demo(
            title: "Concurrency Limiting",
            description: "Limit concurrent operations with token bucket",
            icon: "hourglass.tophalf.filled",
            destination: AnyView(ConcurrencyLimitingDemo())
        ),
        Demo(
            title: "Composing Behaviors",
            description: "Layer multiple loadable behaviors together",
            icon: "square.stack.3d.down.right.fill",
            destination: AnyView(ComposingBehaviorsDemo())
        )
    ]

    @State private var selectedDemo: Demo.ID?

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(demos, selection: $selectedDemo) { demo in
                NavigationLink(value: demo.id) {
                    HStack(spacing: 16) {
                        Image(systemName: demo.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(demo.title)
                                .font(.headline)
                            Text(demo.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityIdentifier(demo.title)
            }
            .navigationTitle("LoadingView Demos")
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            if let selectedDemo = selectedDemo,
               let demo = demos.first(where: { $0.id == selectedDemo }) {
                demo.destination
            } else {
                Text("Select a demo from the list")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
        .navigationSplitViewStyle(.balanced)
        #else
        NavigationStack {
            List(demos) { demo in
                NavigationLink(destination: demo.destination) {
                    HStack(spacing: 16) {
                        Image(systemName: demo.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(demo.title)
                                .font(.headline)
                            Text(demo.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityIdentifier(demo.title)
            }
            .navigationTitle("LoadingView Demos")
            .navigationBarTitleDisplayMode(.large)
        }
        #endif
    }
}
