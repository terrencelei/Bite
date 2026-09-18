import SwiftUI

/// Social tab: your taste twins up top, then a feed of meaningful restaurant activity.
struct SocialFeedView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                tasteTwins
                Text("Activity").sectionTitleStyle().padding(.horizontal)
                if model.feed.isEmpty {
                    emptyFeed
                } else {
                    ForEach(model.feed) { activity in
                        SocialActivityCard(activity: activity)
                            .padding(.horizontal)
                    }
                }
                Color.clear.frame(height: 8)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Social")
        .biteDestinations()
        .navigationDestination(for: EatTogetherRoute.self) { _ in EatTogetherView() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: EatTogetherRoute()) {
                    Label("Eat Together", systemImage: "person.2.badge.gearshape")
                }
            }
        }
    }

    // MARK: Taste twins

    private var tasteTwins: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Taste Twins", subtitle: "Whose taste tracks yours").padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(model.tasteTwins(), id: \.user.id) { twin in
                        NavigationLink(value: twin.user) {
                            VStack(spacing: 8) {
                                FriendAvatar(user: twin.user, size: 64, showRing: twin.match > 0.9, ringColor: Theme.indigo)
                                Text(twin.user.name).font(.subheadline.weight(.semibold))
                                Text(twin.match.asPercent).font(.caption.weight(.bold)).foregroundStyle(Theme.indigo)
                            }
                            .frame(width: 92)
                            .padding(.vertical, 12)
                            .cardSurface()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyFeed: some View {
        ContentUnavailableView("No activity yet", systemImage: "person.2",
                               description: Text("Find friends to see whose taste matches yours."))
            .padding(.top, 20)
    }
}

/// Marker route so "Eat Together" can be pushed via `navigationDestination`.
struct EatTogetherRoute: Hashable {}

/// NOTE: SocialActivityCard uses closures for navigation; because this view embeds its
/// own scroll content in the tab's NavigationStack, we route restaurant/user taps through
/// standard `NavigationLink(value:)` where possible and the closures where not. To keep it
/// robust, wrap the whole feed in the stack's path by appending — handled by the parent
/// NavigationStack in `MainTabView`.
