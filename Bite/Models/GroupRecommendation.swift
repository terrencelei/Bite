import Foundation

/// Per-member predicted satisfaction for a group pick.
struct MemberMatch: Identifiable, Hashable {
    let userID: String
    let score: Double            // 0...1 predicted preference
    var id: String { userID }
}

/// Result of the "Eat Together" flow: a restaurant plus its group score breakdown.
struct GroupPick: Identifiable, Hashable {
    let id: String
    let restaurantID: String
    /// Blended group score = average satisfaction − disagreement penalty (0...1).
    let groupScore: Double
    let memberMatches: [MemberMatch]
    /// Human-readable reason ("Everyone likes modern Chinese and it fits the budget").
    let reason: String
}

/// A configured group-recommendation request.
struct GroupRequest: Hashable {
    var memberIDs: [String]
    var cityID: String
    var maxPrice: PriceLevel
    var occasion: Occasion?
    var cuisineFamily: String?
}
