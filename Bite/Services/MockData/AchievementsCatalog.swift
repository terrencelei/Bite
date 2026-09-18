import Foundation

/// The full, data-driven achievement catalog. Definitions only — progress is computed
/// by `AchievementEngine` against live stats, never hard-coded per view.
enum AchievementsCatalog {

    private static func a(_ id: String, _ name: String, _ desc: String,
                          _ kind: CollectibleKind, _ cat: AchievementCategory,
                          _ rarity: AchievementRarity, _ symbol: String,
                          _ req: AchievementRequirement, hidden: Bool = false) -> Achievement {
        Achievement(id: id, name: name, description: desc, kind: kind, category: cat,
                    rarity: rarity, symbol: symbol, requirement: req, isHiddenUntilClose: hidden)
    }

    // MARK: Exploration — city badges + geography

    static let exploration: [Achievement] = [
        a("shanghai-explorer", "Shanghai Explorer", "Rank 20 restaurants in Shanghai.",
          .badge, .exploration, .common, "building.2.fill", .cityRestaurantCount(cityID: "shanghai", 20)),
        a("shanghai-expert", "Shanghai Expert", "Rank 50 restaurants in Shanghai.",
          .badge, .exploration, .rare, "building.2.fill", .cityRestaurantCount(cityID: "shanghai", 50)),
        a("shanghai-master", "Shanghai Master", "Rank 100 restaurants in Shanghai.",
          .badge, .exploration, .legendary, "crown.fill", .cityRestaurantCount(cityID: "shanghai", 100)),
        a("seoul-explorer", "Seoul Explorer", "Rank 20 restaurants in Seoul.",
          .badge, .exploration, .common, "building.2.fill", .cityRestaurantCount(cityID: "seoul", 20)),
        a("seoul-expert", "Seoul Expert", "Rank 50 restaurants in Seoul.",
          .badge, .exploration, .rare, "building.2.fill", .cityRestaurantCount(cityID: "seoul", 50)),
        a("sf-explorer", "San Francisco Explorer", "Rank 20 restaurants in San Francisco.",
          .badge, .exploration, .common, "building.2.fill", .cityRestaurantCount(cityID: "sf", 20)),
        a("sf-expert", "San Francisco Expert", "Rank 50 restaurants in San Francisco.",
          .badge, .exploration, .rare, "building.2.fill", .cityRestaurantCount(cityID: "sf", 50)),
        a("nyc-explorer", "New York Explorer", "Rank 20 restaurants in New York.",
          .badge, .exploration, .common, "building.2.fill", .cityRestaurantCount(cityID: "nyc", 20)),
        a("nyc-expert", "New York Expert", "Rank 50 restaurants in New York.",
          .badge, .exploration, .rare, "building.2.fill", .cityRestaurantCount(cityID: "nyc", 50)),
        a("neighborhood-explorer", "Neighborhood Explorer", "Rank restaurants across 10 neighborhoods.",
          .badge, .exploration, .uncommon, "map.fill", .neighborhoodCount(10)),
        a("asia-explorer", "Asia Explorer", "Rank restaurants in 5 Asian cities.",
          .award, .exploration, .rare, "globe.asia.australia.fill", .asianCityCount(5)),
        a("globetrotter", "Globetrotter", "Rank restaurants in 5 countries.",
          .award, .exploration, .epic, "airplane", .countryCount(5)),
        a("world-taster", "World Taster", "Rank restaurants in 10 countries.",
          .award, .exploration, .legendary, "globe", .countryCount(10)),
    ]

    // MARK: Stamps — geographic experiences

    static let stamps: [Achievement] = [
        a("stamp-shanghai", "Shanghai", "Rank your first Shanghai restaurant.",
          .stamp, .exploration, .common, "seal.fill", .cityRestaurantCount(cityID: "shanghai", 1)),
        a("stamp-seoul", "Seoul", "Rank your first Seoul restaurant.",
          .stamp, .exploration, .common, "seal.fill", .cityRestaurantCount(cityID: "seoul", 1)),
        a("stamp-tokyo", "Tokyo", "Rank your first Tokyo restaurant.",
          .stamp, .exploration, .common, "seal.fill", .cityRestaurantCount(cityID: "tokyo", 1)),
        a("stamp-sf", "San Francisco", "Rank your first San Francisco restaurant.",
          .stamp, .exploration, .common, "seal.fill", .cityRestaurantCount(cityID: "sf", 1)),
        a("stamp-nyc", "New York", "Rank your first New York restaurant.",
          .stamp, .exploration, .common, "seal.fill", .cityRestaurantCount(cityID: "nyc", 1)),
    ]

    // MARK: Cuisine depth

    static let cuisine: [Achievement] = [
        a("ramen-rookie", "Ramen Rookie", "Rank 5 ramen restaurants.",
          .badge, .cuisine, .common, "bowl.fill", .specificCuisineCount(family: "Ramen", 5)),
        a("ramen-specialist", "Ramen Specialist", "Rank 20 ramen restaurants.",
          .badge, .cuisine, .rare, "bowl.fill", .specificCuisineCount(family: "Ramen", 20)),
        a("sushi-specialist", "Sushi Specialist", "Rank 20 sushi restaurants.",
          .badge, .cuisine, .rare, "fish.fill", .specificCuisineCount(family: "Sushi", 20)),
        a("hotpot-explorer", "Hot Pot Explorer", "Rank 10 hot pot restaurants.",
          .badge, .cuisine, .uncommon, "flame.fill", .specificCuisineCount(family: "Hot Pot", 10)),
        a("sichuan-specialist", "Sichuan Specialist", "Rank 20 Sichuan restaurants.",
          .badge, .cuisine, .rare, "flame.fill", .specificCuisineCount(family: "Sichuan", 20)),
        a("coffee-connoisseur", "Coffee Connoisseur", "Rank 30 cafés.",
          .badge, .cuisine, .rare, "cup.and.saucer.fill", .specificCuisineCount(family: "Café", 30)),
        a("chinese-enthusiast", "Chinese Enthusiast", "Rank 15 Chinese restaurants.",
          .badge, .cuisine, .uncommon, "takeoutbag.and.cup.and.straw.fill", .specificCuisineCount(family: "Chinese", 15)),
        a("korean-enthusiast", "Korean Enthusiast", "Rank 15 Korean restaurants.",
          .badge, .cuisine, .uncommon, "flame.fill", .specificCuisineCount(family: "Korean", 15)),
        a("taste-profile-pro", "Taste Profile Pro", "Build rankings across 10 cuisines.",
          .award, .cuisine, .epic, "square.grid.3x3.fill", .cuisineCount(10)),
    ]

    // MARK: Social

    static let social: [Achievement] = [
        a("first-connection", "First Connection", "Add your first friend.",
          .award, .social, .common, "person.badge.plus", .friendCount(1)),
        a("dinner-crew", "Dinner Crew", "Reach 10 friends.",
          .award, .social, .uncommon, "person.2.fill", .friendCount(10)),
        a("social-foodie", "Social Foodie", "Reach 25 friends.",
          .award, .social, .rare, "person.3.fill", .friendCount(25)),
        a("taste-network", "Taste Network", "Reach 50 friends.",
          .award, .social, .epic, "person.3.sequence.fill", .friendCount(50)),
        a("taste-twin", "Taste Twin", "Find a friend with over 90% taste match.",
          .award, .social, .rare, "figure.2.arms.open", .tasteMatchThreshold(0.9)),
        a("matchmaker", "Matchmaker", "Complete 5 group recommendations.",
          .award, .social, .rare, "sparkles", .groupRecommendationCount(5)),
    ]

    // MARK: Discovery

    static let discovery: [Achievement] = [
        a("early-explorer", "Early Explorer", "Be early to 3 restaurants before they trended.",
          .award, .discovery, .rare, "sparkle.magnifyingglass", .earlyDiscoveryCount(3)),
        a("trend-spotter", "Trend Spotter", "Be early to 8 restaurants before they trended.",
          .award, .discovery, .epic, "chart.line.uptrend.xyaxis", .earlyDiscoveryCount(8)),
        a("taste-maker", "Taste Maker", "Be early to 15 restaurants before they trended.",
          .award, .discovery, .legendary, "wand.and.stars", .earlyDiscoveryCount(15), hidden: true),
    ]

    // MARK: Ranking

    static let ranking: [Achievement] = [
        a("first-ranking", "First Ranking", "Rank your first restaurant.",
          .award, .ranking, .common, "list.number", .restaurantCount(1)),
        a("getting-serious", "Getting Serious", "Rank 10 restaurants.",
          .award, .ranking, .common, "list.number", .restaurantCount(10)),
        a("food-critic", "Food Critic", "Rank 50 restaurants.",
          .award, .ranking, .rare, "star.leadinghalf.filled", .restaurantCount(50)),
        a("century-club", "Century Club", "Rank 100 restaurants.",
          .award, .ranking, .epic, "100.circle.fill", .restaurantCount(100)),
        a("deep-taste", "Deep Taste", "Complete 100 pairwise comparisons.",
          .award, .ranking, .rare, "arrow.left.arrow.right", .pairwiseComparisonCount(100)),
        a("world-ranking", "World Ranking", "Maintain rankings across 5 cities.",
          .award, .ranking, .epic, "globe.americas.fill", .cityCount(5)),
    ]

    // MARK: Restaurant collections & Michelin

    static let collectionsCategory: [Achievement] = [
        a("shanghai-essentials", "Shanghai Essentials", "Rank 5 iconic Shanghai restaurants.",
          .stamp, .collection, .rare, "seal.fill", .collectionCompleted(collectionID: "shanghai-essentials")),
        a("seoul-essentials", "Seoul Essentials", "Rank 5 iconic Seoul restaurants.",
          .stamp, .collection, .rare, "seal.fill", .collectionCompleted(collectionID: "seoul-essentials")),
        a("nyc-classics", "NYC Classics", "Rank 5 iconic New York restaurants.",
          .stamp, .collection, .rare, "seal.fill", .collectionCompleted(collectionID: "nyc-classics")),
        a("michelin-explorer", "Michelin Explorer", "Rank 5 Michelin-recognized restaurants.",
          .award, .collection, .epic, "star.circle.fill", .michelinCount(5)),
        a("landmark-collector", "Landmark Collector", "Rank 10 landmark restaurants.",
          .award, .collection, .rare, "mappin.and.ellipse", .landmarkRestaurantCount(10)),
    ]

    /// The complete catalog.
    static let all: [Achievement] =
        exploration + stamps + cuisine + social + discovery + ranking + collectionsCategory

    static func by(id: String) -> Achievement? { all.first { $0.id == id } }
}
