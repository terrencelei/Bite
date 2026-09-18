import Foundation

/// A configured contextual request from the "What are you looking for?" flow.
/// All fields optional/defaulted so the flow stays fast and playful.
struct RecommendationContext: Hashable {
    var occasion: Occasion?
    var cuisineFamily: String?
    var maxPrice: PriceLevel?
    var maxDistanceKm: Double?
    var partySize: Int = 2
    var neighborhood: String?
    var newRestaurantsOnly: Bool = false
    var upscale: Bool? = nil          // nil = no preference, true = upscale, false = casual
    var cityID: String?

    static let empty = RecommendationContext()
}

/// One scored recommendation with its explanation — the payload behind every card.
struct Recommendation: Identifiable, Hashable {
    let restaurantID: String
    /// Final blended score, normalized into a believable 0...1 "match".
    let matchScore: Double
    /// The component scores, retained for transparency/debugging.
    let breakdown: ScoreBreakdown
    /// Human-readable reasons ("You love Sichuan", "Jason loved it", "12 min away").
    let reasons: [String]
    /// Friends whose activity supports this pick (for the friend row).
    let supportingFriendIDs: [String]

    var id: String { restaurantID }

    struct ScoreBreakdown: Hashable {
        var taste: Double
        var friend: Double
        var context: Double
        var popularity: Double
        var novelty: Double
    }
}

/// A curated landmark collection (Shanghai Essentials, NYC Classics, Michelin Explorer…).
struct RestaurantCollection: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    /// Restaurant IDs that count toward completion.
    let restaurantIDs: [String]
}
