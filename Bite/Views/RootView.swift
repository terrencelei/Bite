import SwiftUI

/// App root. Shows onboarding on first run, then the main tab UI, and floats the
/// achievement-unlock celebration above everything when the engine reports a new unlock.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(NearbySearchStore.self) private var nearby

    /// Debug-only: `BITE_SCREEN` env var jumps straight to a screen for screenshotting.
    private var debugScreen: String? {
        #if DEBUG
        guard model.demoMode else { return nil }
        let v = ProcessInfo.processInfo.environment["BITE_SCREEN"]
        return (v?.isEmpty ?? true) ? nil : v
        #else
        return nil
        #endif
    }

    var body: some View {
        ZStack {
            if model.storageReadFailed {
                ContentUnavailableView("Saved data unavailable", systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(model.storageError ?? "Close and reopen Bite to retry."))
            } else if let screen = debugScreen {
                DebugScreenHost(screen: screen)
            } else if model.onboardingComplete {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }

            // Achievement celebration overlay (queue-driven).
            if let unlock = model.pendingUnlocks.first {
                AchievementUnlockView(achievement: unlock) {
                    withAnimation(.spring) {
                        if !model.pendingUnlocks.isEmpty { model.pendingUnlocks.removeFirst() }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                .zIndex(10)
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = model.storageError, !model.storageReadFailed {
                HStack {
                    Text(error).font(.footnote)
                    Button("Retry") { model.persist() }
                }.padding().background(.regularMaterial)
            }
        }
        .onChange(of: model.onboardingComplete) { _, complete in
            if !complete { nearby.clear() }
        }
        .animation(.easeInOut, value: model.onboardingComplete)
        .animation(.spring, value: model.pendingUnlocks.count)
    }
}

/// Debug host: renders a single deep screen based on an env var (for verification shots).
private struct DebugScreenHost: View {
    @Environment(AppModel.self) private var model
    let screen: String
    var body: some View {
        NavigationStack {
            switch screen {
            case "detail": RestaurantDetailView(restaurant: model.restaurant("sh-linglong")!)
            case "ranking": RankingFlowView(restaurant: model.restaurant("sh-hakkasan")!)
            case "achievements": AchievementsView()
            case "passport": FoodPassportView()
            case "eat": EatTogetherView()
            case "friend": FriendProfileView(user: model.user("u-jason")!)
            case "context": ContextualRecommendationView(presetOccasion: .dateNight)
            case "unlock":
                AchievementUnlockView(achievement: model.achievementByID["taste-profile-pro"]!) {}
            default: DiscoverView()
            }
        }
    }
}

/// Five-destination tab bar. Each tab owns its own `NavigationStack`.
struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: AppTab = {
        switch ProcessInfo.processInfo.environment["BITE_TAB"] {
        case "social": return .social
        case "map": return .map
        case "rankings": return .rankings
        case "profile": return .profile
        default: return .discover
        }
    }()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { NearbyRestaurantsView() }
                .tabItem { Label("Discover", systemImage: "sparkles") }
                .tag(AppTab.discover)

            NavigationStack { SavedRestaurantsView() }
                .tabItem { Label("Saved", systemImage: "bookmark.fill") }
                .tag(AppTab.social)

            NavigationStack { MapScreen() }
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(AppTab.map)

            NavigationStack { RankingsView() }
                .tabItem { Label("Rankings", systemImage: "list.number") }
                .tag(AppTab.rankings)

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .tint(Theme.accent)
    }
}
