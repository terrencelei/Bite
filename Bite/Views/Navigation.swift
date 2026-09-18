import SwiftUI

/// Shared navigation destinations so any `NavigationLink(value:)` works from any tab.
/// Applied once per `NavigationStack`.
extension View {
    func biteDestinations() -> some View {
        self
            .navigationDestination(for: Restaurant.self) { RestaurantDetailView(restaurant: $0) }
            .navigationDestination(for: User.self) { FriendProfileView(user: $0) }
            .navigationDestination(for: Achievement.self) { AchievementDetailView(achievement: $0) }
            .navigationDestination(for: RankingScope.self) { RankingDetailView(scope: $0) }
            .navigationDestination(for: PassportCity.self) { CityDetailView(cityID: $0.cityID) }
    }
}

/// Lightweight tab identity. (Named `AppTab` to avoid colliding with SwiftUI's `Tab`.)
enum AppTab: Hashable { case discover, social, map, rankings, profile }
