import LoadingView
import SwiftUI

/// Demonstrates managing multiple independent loaders within a single view.
struct MultipleLoadersDemo: View {
    @State private var userLoader = BlockLoadable {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return User(name: "John Doe", avatar: "person.circle.fill", status: "Active")
    }

    @State private var statsLoader = BlockLoadable {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return Stats(posts: 42, followers: 1234, following: 567)
    }

    @State private var activityLoader = BlockLoadable {
        try await Task.sleep(nanoseconds: 2_500_000_000)
        return [
            "Posted a new photo",
            "Liked 3 posts",
            "Started following @swift",
            "Commented on a discussion"
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                UserProfileSection(loader: userLoader)

                StatisticsSection(loader: statsLoader)

                RecentActivitySection(loader: activityLoader)

                ControlSection(
                    userLoader: userLoader,
                    statsLoader: statsLoader,
                    activityLoader: activityLoader
                )
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Multiple Loaders")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}