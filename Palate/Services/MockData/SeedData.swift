import Foundation

/// Seeds the current user's starting world: their rankings, visits, friend signals,
/// social feed, and challenges.
///
/// The ranking seed deliberately covers exactly **9 distinct cuisine families** (Sushi,
/// Japanese, Italian, French & Thai are left unranked), so "Taste Profile Pro" (10
/// cuisines) sits at 9/10 — ranking a single sushi/Italian spot during a demo unlocks it.
enum SeedData {

    /// A reference "now" the seed dates hang off, so relative times stay sensible.
    static func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }

    // Restaurant IDs the current user has ranked, best-first. Scores descend from 95.
    private static let rankedOrder: [String] = [
        // Shanghai
        "sh-fuhehui", "sh-yushang", "sh-dintaifung", "sh-seesaw", "sh-haidilao",
        "sh-egg", "sh-ramenishikawa", "sh-yunnanteng", "sh-laozhengxing", "sh-pudongtea",
        // Seoul
        "se-gwangjang", "se-seongsucoffee", "se-parkhae", "se-eomeoni", "se-nudake",
        // SF
        "sf-lataqueria", "sf-tartine", "sf-marufuku", "sf-sightglass",
        // NYC
        "ny-xianfamous", "ny-veselka", "ny-superiority",
        // Tokyo
        "tk-ichiran", "tk-nakameguro",
    ]

    /// Current user's ranking entries (latent scores spaced so leaderboards read well).
    static var rankings: [RankingEntry] {
        rankedOrder.enumerated().map { i, rid in
            RankingEntry(
                id: "rank-\(rid)", restaurantID: rid,
                score: 95 - Double(i) * 1.6,
                comparisons: Int.random(in: 3...6),
                dateRanked: daysAgo(3 + i * 4)
            )
        }
    }

    /// Visits mirror rankings (ranked ⇒ been), a couple carry quality tags.
    static var visits: [RestaurantVisit] {
        rankedOrder.enumerated().map { i, rid in
            let tags: [QualityTag]
            switch i {
            case 0: tags = [.creativity, .atmosphere]
            case 1: tags = [.food, .authenticity, .value]
            case 10: tags = [.value, .authenticity]
            default: tags = []
            }
            return RestaurantVisit(id: "visit-\(rid)", restaurantID: rid, date: daysAgo(3 + i * 4), qualityTags: tags)
        }
    }

    /// Persisted activity counters (naturally cumulative — increment with real use).
    static let seededComparisonCount = 84       // Deep Taste: 84/100
    static let seededGroupRecCount = 3          // Matchmaker: 3/5

    // MARK: Friend signals

    /// What each friend ranks in their personal top tier (drives FriendScore + reasons).
    static let friendTopPicks: [String: [String]] = [
        "u-jason":  ["sh-yushang", "sh-fuhehui", "se-parkhae", "tk-ichiran", "sh-linglong"],
        "u-emily":  ["sh-fuhehui", "sh-egg", "se-nudake", "sf-tartine", "sh-dintaifung"],
        "u-kevin":  ["se-gwangjang", "sh-yushang", "ny-xianfamous", "sf-lataqueria", "sh-haidilao"],
        "u-alex":   ["ny-rezdora", "sf-benu", "sf-zuni", "ny-lucali"],
        "u-mina":   ["se-mingles", "se-seongsucoffee", "se-nudake", "se-jungsik"],
        "u-diego":  ["sf-lataqueria", "se-itaewontaco", "ny-xianfamous", "sf-marufuku"],
        "u-sophie": ["ny-atomix", "sh-linglong", "tk-birdland", "se-mingles"],
        "u-ryan":   ["sf-marufuku", "sh-ramenishikawa", "tk-ichiran", "sh-yushang"],
    ]

    /// What each friend wants to try (weaker positive signal).
    static let friendWantToTry: [String: [String]] = [
        "u-jason":  ["sh-linglong", "sh-sushioomori"],
        "u-emily":  ["sh-linglong", "se-seongsucoffee"],
        "u-kevin":  ["sh-yunnanteng"],
        "u-sophie": ["sh-fuhehui", "tk-sukiyabashi"],
        "u-ryan":   ["se-parkhae"],
    ]

    /// Human scope labels a friend's ranking implies, e.g. "#1 for Sichuan".
    static let friendScopeLabels: [String: [String: String]] = [
        "u-jason":  ["sh-yushang": "#1 for Sichuan", "sh-fuhehui": "#2 in Shanghai"],
        "u-kevin":  ["se-gwangjang": "#1 for street food"],
        "u-mina":   ["se-mingles": "#1 in Seoul"],
        "u-sophie": ["ny-atomix": "#1 in New York"],
    ]

    // MARK: Social feed

    static var feed: [SocialActivity] {
        [
            SocialActivity(id: "f1", userID: "u-jason",
                           kind: .ranked(restaurantID: "sh-fuhehui", position: 2, scope: "Shanghai"),
                           date: daysAgo(0), likeCount: 12, commentCount: 3),
            SocialActivity(id: "f2", userID: "u-mina",
                           kind: .earnedAchievement(achievementID: "seoul-expert"),
                           date: daysAgo(1), likeCount: 24, commentCount: 5),
            SocialActivity(id: "f3", userID: "u-emily",
                           kind: .newFavorite(restaurantID: "se-nudake"),
                           date: daysAgo(1), likeCount: 9, commentCount: 1),
            SocialActivity(id: "f4", userID: "u-ryan",
                           kind: .earlyDiscovery(restaurantID: "sh-ramenishikawa"),
                           date: daysAgo(2), likeCount: 18, commentCount: 4),
            SocialActivity(id: "f5", userID: "u-kevin",
                           kind: .wantToTry(restaurantID: "sh-yunnanteng"),
                           date: daysAgo(2), likeCount: 4, commentCount: 0),
            SocialActivity(id: "f6", userID: "u-sophie",
                           kind: .ranked(restaurantID: "ny-atomix", position: 1, scope: "New York"),
                           date: daysAgo(3), likeCount: 31, commentCount: 8),
            SocialActivity(id: "f7", userID: "u-diego",
                           kind: .newFavorite(restaurantID: "sf-lataqueria"),
                           date: daysAgo(4), likeCount: 15, commentCount: 2),
            SocialActivity(id: "f8", userID: "u-jason",
                           kind: .earnedAchievement(achievementID: "sushi-specialist"),
                           date: daysAgo(5), likeCount: 27, commentCount: 6),
            SocialActivity(id: "f9", userID: "u-alex",
                           kind: .ranked(restaurantID: "ny-rezdora", position: 3, scope: "New York"),
                           date: daysAgo(6), likeCount: 11, commentCount: 1),
        ]
    }

    // MARK: Challenges

    static let challenges: [Challenge] = [
        Challenge(id: "c-newhoods", title: "Explore Somewhere New",
                  subtitle: "Rank restaurants in 3 new neighborhoods", symbol: "map.fill",
                  target: 3, progress: 1, timeframe: nil),
        Challenge(id: "c-newcuisines", title: "Try Something New",
                  subtitle: "Rank 3 cuisines you rarely eat", symbol: "sparkles",
                  target: 3, progress: 0, timeframe: nil),
        Challenge(id: "c-shmonth", title: "Shanghai This Month",
                  subtitle: "Rank 5 new Shanghai restaurants", symbol: "building.2.fill",
                  target: 5, progress: 2, timeframe: "This month"),
        Challenge(id: "c-friendsdinner", title: "Friends Dinner",
                  subtitle: "Complete a group rec and rank the result", symbol: "person.2.fill",
                  target: 1, progress: 0, timeframe: nil),
    ]

    /// A couple of achievements shown as "recently unlocked" for the demo, with dates.
    /// (These also legitimately unlock from the seed data; the dates just make them recent.)
    static let recentlyUnlockedDates: [String: Date] = [
        "early-explorer": daysAgo(2),
        "world-ranking": daysAgo(6),
    ]
}
