import Foundation

/// A record that the current user has been to a restaurant.
struct RestaurantVisit: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    var date: Date
    /// Tags from "what made it better?" — feed the taste model.
    var qualityTags: [QualityTag]
}

/// Signals collected after a visit; each maps onto taste dimensions.
enum QualityTag: String, CaseIterable, Codable, Hashable, Identifiable {
    case food, value, atmosphere, service, creativity, authenticity
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    /// Which taste dimensions this tag reinforces.
    var dimensions: [TasteDimension] {
        switch self {
        case .food: return [.authenticity]
        case .value: return [.value]
        case .atmosphere: return [.atmosphere]
        case .service: return [.fineDining]
        case .creativity: return [.novelty]
        case .authenticity: return [.authenticity]
        }
    }
}

/// The user's personal ranking entry for a restaurant.
///
/// `score` is a latent strength (Bradley-Terry style). Rankings within a scope are
/// derived by sorting on `score`; the raw value is never shown to users.
struct RankingEntry: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    var score: Double            // latent strength, typically ~0...100
    var comparisons: Int         // how many pairwise comparisons informed this
    var dateRanked: Date
    /// Marks a freshly inserted entry so the leaderboard can animate a "NEW" badge.
    var isNew: Bool = false
}

/// One A/B comparison the user resolved during a ranking flow.
struct PairwiseComparison: Identifiable, Codable, Hashable {
    let id: String
    let winnerID: String
    let loserID: String
    let date: Date
}
