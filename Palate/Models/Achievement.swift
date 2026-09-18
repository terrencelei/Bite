import Foundation

// MARK: - Rarity & categories

enum AchievementRarity: Int, Codable, CaseIterable, Comparable, Hashable {
    case common, uncommon, rare, epic, legendary
    static func < (l: AchievementRarity, r: AchievementRarity) -> Bool { l.rawValue < r.rawValue }
}

/// The three conceptual buckets — Badges (expertise), Stamps (places/experiences),
/// Awards (unusual accomplishments) — plus the functional grouping used on the
/// achievements screen.
enum CollectibleKind: String, Codable, Hashable {
    case badge, stamp, award
    var label: String {
        switch self {
        case .badge: return "Badge"
        case .stamp: return "Stamp"
        case .award: return "Award"
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case exploration, cuisine, social, discovery, collection, ranking
    var id: String { rawValue }
    var title: String {
        switch self {
        case .exploration: return "Exploration"
        case .cuisine: return "Cuisine"
        case .social: return "Social"
        case .discovery: return "Discovery"
        case .collection: return "Restaurant Collections"
        case .ranking: return "Ranking"
        }
    }
    var symbol: String {
        switch self {
        case .exploration: return "map.fill"
        case .cuisine: return "fork.knife"
        case .social: return "person.2.fill"
        case .discovery: return "sparkle.magnifyingglass"
        case .collection: return "seal.fill"
        case .ranking: return "list.number"
        }
    }
}

// MARK: - Requirements

/// A data-driven requirement. The `AchievementEngine` computes progress for each of
/// these against the user's live stats — no per-achievement logic lives in views.
enum AchievementRequirement: Codable, Hashable {
    case restaurantCount(Int)
    case cityRestaurantCount(cityID: String, Int)
    case countryCount(Int)
    case cityCount(Int)
    case asianCityCount(Int)
    case neighborhoodCount(Int)                 // distinct neighborhoods anywhere
    case cityNeighborhoodCount(cityID: String, Int)
    case cuisineCount(Int)                       // distinct cuisine families ranked
    case specificCuisineCount(family: String, Int)
    case friendCount(Int)
    case pairwiseComparisonCount(Int)
    case groupRecommendationCount(Int)
    case tasteMatchThreshold(Double)             // has any friend above this match
    case landmarkRestaurantCount(Int)
    case michelinCount(Int)
    case earlyDiscoveryCount(Int)
    case collectionCompleted(collectionID: String)   // all landmark IDs visited

    /// The target count that defines "100%". Threshold-style requirements return 1.
    var threshold: Int {
        switch self {
        case .restaurantCount(let n), .countryCount(let n), .cityCount(let n),
             .asianCityCount(let n), .neighborhoodCount(let n), .cuisineCount(let n),
             .friendCount(let n), .pairwiseComparisonCount(let n),
             .groupRecommendationCount(let n), .landmarkRestaurantCount(let n),
             .michelinCount(let n), .earlyDiscoveryCount(let n):
            return n
        case .cityRestaurantCount(_, let n), .cityNeighborhoodCount(_, let n),
             .specificCuisineCount(_, let n):
            return n
        case .tasteMatchThreshold, .collectionCompleted:
            return 1
        }
    }
}

// MARK: - Achievement definition

/// Static definition of an achievement. Progress is computed at runtime, keeping the
/// catalog immutable and data-driven.
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let kind: CollectibleKind
    let category: AchievementCategory
    let rarity: AchievementRarity
    let symbol: String
    let requirement: AchievementRequirement
    /// Some rare achievements stay teased until the user is close.
    var isHiddenUntilClose: Bool = false
}

/// Runtime progress toward an achievement (persisted for unlocked ones).
struct AchievementProgress: Identifiable, Codable, Hashable {
    let achievementID: String
    var current: Int
    var target: Int
    var isUnlocked: Bool
    var unlockedDate: Date?

    var id: String { achievementID }
    var fraction: Double { target <= 0 ? 0 : min(1, Double(current) / Double(target)) }
    var remaining: Int { max(0, target - current) }
}
