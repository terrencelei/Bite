import Foundation

/// A snapshot of everything achievements can depend on. Built once by the store from
/// live user data, then handed to the engine — so achievement logic never reaches
/// into views or the store directly.
struct AchievementStats {
    var totalRanked = 0
    var rankedByCity: [String: Int] = [:]
    var countries: Set<String> = []
    var cities: Set<String> = []
    var asianCities: Set<String> = []
    var neighborhoods: Set<String> = []                      // "cityID|neighborhood"
    var neighborhoodsByCity: [String: Set<String>] = [:]
    var cuisineFamilies: Set<String> = []
    var cuisineFamilyCounts: [String: Int] = [:]
    var friendCount = 0
    var pairwiseComparisons = 0
    var groupRecommendations = 0
    var bestFriendMatch = 0.0
    var landmarksVisited = 0
    var michelinVisited = 0
    var earlyDiscoveries = 0
    /// Per-collection: how many of its restaurants the user has ranked, and its total size.
    var collectionMatched: [String: Int] = [:]
    var collectionTotal: [String: Int] = [:]
}

/// Evaluates the achievement catalog against user stats. Modular and stateless: pass
/// it stats + the set of already-unlocked IDs and it returns fresh progress plus any
/// newly-crossed unlocks for the celebration layer.
struct AchievementEngine {

    /// Compute (current, target) progress for one requirement.
    func progress(for req: AchievementRequirement, stats: AchievementStats) -> (current: Int, target: Int) {
        switch req {
        case .restaurantCount(let n):
            return (stats.totalRanked, n)
        case .cityRestaurantCount(let city, let n):
            return (stats.rankedByCity[city] ?? 0, n)
        case .countryCount(let n):
            return (stats.countries.count, n)
        case .cityCount(let n):
            return (stats.cities.count, n)
        case .asianCityCount(let n):
            return (stats.asianCities.count, n)
        case .neighborhoodCount(let n):
            return (stats.neighborhoods.count, n)
        case .cityNeighborhoodCount(let city, let n):
            return (stats.neighborhoodsByCity[city]?.count ?? 0, n)
        case .cuisineCount(let n):
            return (stats.cuisineFamilies.count, n)
        case .specificCuisineCount(let family, let n):
            return (stats.cuisineFamilyCounts[family] ?? 0, n)
        case .friendCount(let n):
            return (stats.friendCount, n)
        case .pairwiseComparisonCount(let n):
            return (stats.pairwiseComparisons, n)
        case .groupRecommendationCount(let n):
            return (stats.groupRecommendations, n)
        case .tasteMatchThreshold(let t):
            return (stats.bestFriendMatch >= t ? 1 : 0, 1)
        case .landmarkRestaurantCount(let n):
            return (stats.landmarksVisited, n)
        case .michelinCount(let n):
            return (stats.michelinVisited, n)
        case .earlyDiscoveryCount(let n):
            return (stats.earlyDiscoveries, n)
        case .collectionCompleted(let id):
            return (stats.collectionMatched[id] ?? 0, stats.collectionTotal[id] ?? 1)
        }
    }

    /// Result of evaluating the full catalog.
    struct Evaluation {
        var progress: [AchievementProgress]
        var newlyUnlocked: [Achievement]
    }

    /// Evaluate the whole catalog. `previouslyUnlocked` maps achievementID -> unlock date
    /// so already-earned achievements keep their original date and don't re-fire.
    func evaluate(catalog: [Achievement],
                  stats: AchievementStats,
                  previouslyUnlocked: [String: Date],
                  now: Date) -> Evaluation {
        var progresses: [AchievementProgress] = []
        var newlyUnlocked: [Achievement] = []

        for achievement in catalog {
            let (current, target) = progress(for: achievement.requirement, stats: stats)
            let wasUnlocked = previouslyUnlocked[achievement.id] != nil
            let meetsNow = current >= target && target > 0
            let isUnlocked = wasUnlocked || meetsNow

            let unlockedDate: Date? = wasUnlocked ? previouslyUnlocked[achievement.id]
                                                  : (meetsNow ? now : nil)

            if meetsNow && !wasUnlocked {
                newlyUnlocked.append(achievement)
            }

            progresses.append(AchievementProgress(
                achievementID: achievement.id,
                current: min(current, target),
                target: target,
                isUnlocked: isUnlocked,
                unlockedDate: unlockedDate
            ))
        }

        // Surface the rarest new unlock first, so celebrations feel appropriately weighted.
        newlyUnlocked.sort { lhs, rhs in lhs.rarity > rhs.rarity }
        return Evaluation(progress: progresses, newlyUnlocked: newlyUnlocked)
    }
}
