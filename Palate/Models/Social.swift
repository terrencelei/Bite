import Foundation

/// A single item in the social feed. Modeled around *meaningful restaurant activity*
/// (rankings, discoveries, achievements) rather than generic photo posts.
struct SocialActivity: Identifiable, Codable, Hashable {
    let id: String
    let userID: String
    let kind: Kind
    let date: Date
    var likeCount: Int
    var commentCount: Int
    var likedByCurrentUser: Bool = false

    enum Kind: Codable, Hashable {
        /// Friend ranked a restaurant at a given position within a scope.
        case ranked(restaurantID: String, position: Int, scope: String)
        /// Friend marked a new favorite.
        case newFavorite(restaurantID: String)
        /// Friend wants to try a restaurant.
        case wantToTry(restaurantID: String)
        /// Friend earned an achievement.
        case earnedAchievement(achievementID: String)
        /// Friend discovered a restaurant before it trended.
        case earlyDiscovery(restaurantID: String)
    }

    /// Restaurant this activity references, if any (for tap-through + cards).
    var referencedRestaurantID: String? {
        switch kind {
        case .ranked(let id, _, _): return id
        case .newFavorite(let id): return id
        case .wantToTry(let id): return id
        case .earlyDiscovery(let id): return id
        case .earnedAchievement: return nil
        }
    }

    var referencedAchievementID: String? {
        if case .earnedAchievement(let id) = kind { return id }
        return nil
    }
}

/// A comment on a feed item (kept local + lightweight).
struct FeedComment: Identifiable, Codable, Hashable {
    let id: String
    let activityID: String
    let userID: String
    let text: String
    let date: Date
}
