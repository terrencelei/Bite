import Foundation
import Observation

/// The single source of truth for the running app. Holds the immutable mock catalog plus
/// the mutable, persisted user state, and coordinates the recommendation / ranking /
/// achievement engines. Views observe this and call its intent methods — no view reaches
/// into an engine directly.
@MainActor
@Observable
final class AppModel {

    // MARK: Live place catalog and static definitions

    private(set) var restaurants: [Restaurant]
    private(set) var restaurantByID: [String: Restaurant]
    let allUsers: [User]
    let userByID: [String: User]
    private(set) var cities: [City]
    private(set) var cityByID: [String: City]
    let collections: [RestaurantCollection]
    let achievementsCatalog: [Achievement]
    let achievementByID: [String: Achievement]

    // MARK: Mutable user state (persisted)

    var currentUser: User
    var rankings: [RankingEntry]
    var visits: [RestaurantVisit]
    var wantToTryIDs: Set<String>
    var friendIDs: [String]
    var comparisonCount: Int
    var groupRecCount: Int
    var unlockedAchievements: [String: Date]
    var featuredAchievementIDs: [String]
    var likedActivityIDs: Set<String>
    var challenges: [Challenge]
    var feed: [SocialActivity]
    var onboardingComplete: Bool

    // MARK: Derived achievement state

    /// achievementID -> current progress (recomputed on every change).
    private(set) var achievementProgress: [String: AchievementProgress] = [:]
    /// Newly-crossed achievements waiting to be celebrated by the UI.
    var pendingUnlocks: [Achievement] = []

    // MARK: Engines & services

    private let persistence: PersistenceService
    let recommender: RecommendationEngine = RecommendationEngine()
    let groupEngine: GroupRecommendationEngine = GroupRecommendationEngine()
    private let achievementEngine = AchievementEngine()

    let demoMode: Bool
    var storageError: String?
    private var canSave = true
    var storageReadFailed: Bool { !canSave }

    // MARK: Init

    init(persistence: PersistenceService = FilePersistenceService(), demoMode: Bool = false) {
        self.demoMode = demoMode
        self.persistence = persistence

        // Catalog.
        let saved: PersistedState?
        do { saved = try persistence.load() }
        catch {
            saved = nil
            canSave = false
            storageError = "Your saved data could not be read. It has been preserved. Close and reopen Bite to retry."
        }
        let restaurants = saved?.restaurants ?? (demoMode ? Restaurants.all : [])
        self.restaurants = restaurants
        self.restaurantByID = Dictionary(restaurants.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        self.allUsers = demoMode ? Users.all : [User.local]
        self.userByID = Dictionary(uniqueKeysWithValues: (demoMode ? Users.all : [User.local]).map { ($0.id, $0) })
        let initialCities = saved?.cities ?? (demoMode ? Cities.all : [])
        self.cities = initialCities
        self.cityByID = Dictionary(initialCities.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        self.collections = demoMode ? Collections.all : []
        self.achievementsCatalog = AchievementsCatalog.all.filter { achievement in
            if demoMode { return true }
            switch achievement.requirement {
            case .restaurantCount, .countryCount, .cityCount, .asianCityCount, .pairwiseComparisonCount: return true
            default: return false
            }
        }
        self.achievementByID = Dictionary(uniqueKeysWithValues: AchievementsCatalog.all.map { ($0.id, $0) })

        // State: restore from disk or seed a fresh world.
        if let saved {
            self.onboardingComplete = saved.onboardingComplete
            self.rankings = saved.rankings
            self.visits = saved.visits
            self.wantToTryIDs = Set(saved.wantToTryIDs)
            self.friendIDs = saved.friendIDs
            self.comparisonCount = saved.comparisonCount
            self.groupRecCount = saved.groupRecCount
            self.unlockedAchievements = saved.unlockedAchievements
            self.featuredAchievementIDs = saved.featuredAchievementIDs
            self.likedActivityIDs = Set(saved.likedActivityIDs)
            self.challenges = saved.challenges
            var user = saved.user ?? (demoMode ? Users.terrence : User.local)
            if let prefs = saved.preferences { user.preferences = prefs }
            self.currentUser = user
            self.feed = saved.feed ?? (demoMode ? SeedData.feed : [])
            if saved.feed == nil {
                for i in feed.indices where likedActivityIDs.contains(feed[i].id) {
                    feed[i].likedByCurrentUser = true
                    feed[i].likeCount += 1
                }
            }
        } else {
            // Example data is opt-in for tests; the app starts with a clean local profile.
            self.onboardingComplete = demoMode
            self.rankings = demoMode ? SeedData.rankings : []
            self.visits = demoMode ? SeedData.visits : []
            self.wantToTryIDs = demoMode ? ["sh-linglong", "sh-hakkasan", "se-mingles", "ny-atomix"] : []
            self.friendIDs = demoMode ? Users.friends.map(\.id) : []
            self.comparisonCount = demoMode ? SeedData.seededComparisonCount : 0
            self.groupRecCount = demoMode ? SeedData.seededGroupRecCount : 0
            self.unlockedAchievements = demoMode ? SeedData.recentlyUnlockedDates : [:]
            self.featuredAchievementIDs = []
            self.likedActivityIDs = []
            self.challenges = demoMode ? SeedData.challenges : []
            self.currentUser = demoMode ? Users.terrence : User.local
            self.feed = demoMode ? SeedData.feed : []
        }

        recomputeAchievements(celebrate: false)
        if featuredAchievementIDs.isEmpty { autoFeatureAchievements() }
    }

    // MARK: Persistence

    func persist() {
        var state = PersistedState()
        state.onboardingComplete = onboardingComplete
        state.rankings = rankings
        state.visits = visits
        state.wantToTryIDs = Array(wantToTryIDs)
        state.friendIDs = friendIDs
        state.comparisonCount = comparisonCount
        state.groupRecCount = groupRecCount
        state.unlockedAchievements = unlockedAchievements
        state.featuredAchievementIDs = featuredAchievementIDs
        state.likedActivityIDs = Array(likedActivityIDs)
        state.preferences = currentUser.preferences
        state.challenges = challenges
        guard canSave else { return }
        state.feed = feed
        state.user = currentUser
        let retained = rankedRestaurantIDs.union(wantToTryIDs).union(visits.map(\.restaurantID))
        state.restaurants = restaurants.filter { retained.contains($0.id) }
        state.cities = cities
        do { try persistence.save(state); storageError = nil }
        catch { storageError = "Changes could not be saved. Free some device storage, then tap Retry." }
    }

    /// Delete live user state, or restore fixtures when explicitly running a demo.
    func resetToSeed() {
        do { try persistence.reset() }
        catch { storageError = "Could not reset your data. Please try again."; return }
        canSave = true
        storageError = nil
        pendingUnlocks = []
        restaurants = demoMode ? Restaurants.all : []
        restaurantByID = Dictionary(restaurants.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        cities = demoMode ? Cities.all : []
        cityByID = Dictionary(uniqueKeysWithValues: cities.map { ($0.id, $0) })
        onboardingComplete = false
        rankings = demoMode ? SeedData.rankings : []
        visits = demoMode ? SeedData.visits : []
        wantToTryIDs = demoMode ? ["sh-linglong", "sh-hakkasan", "se-mingles", "ny-atomix"] : []
        friendIDs = demoMode ? Users.friends.map(\.id) : []
        comparisonCount = demoMode ? SeedData.seededComparisonCount : 0
        groupRecCount = demoMode ? SeedData.seededGroupRecCount : 0
        unlockedAchievements = demoMode ? SeedData.recentlyUnlockedDates : [:]
        featuredAchievementIDs = []
        likedActivityIDs = []
        challenges = demoMode ? SeedData.challenges : []
        currentUser = demoMode ? Users.terrence : User.local
        feed = demoMode ? SeedData.feed : []
        recomputeAchievements(celebrate: false)
        autoFeatureAchievements()
        persist()
    }

    // MARK: Convenience lookups

    var rankedRestaurantIDs: Set<String> { Set(rankings.map(\.restaurantID)) }
    var friends: [User] { friendIDs.compactMap { userByID[$0] } }
    var homeCityID: String { currentUser.cityIDs.first ?? "shanghai" }

    func restaurant(_ id: String) -> Restaurant? { restaurantByID[id] }
    func user(_ id: String) -> User? { id == currentUser.id ? currentUser : userByID[id] }
    func city(_ id: String) -> City? { cityByID[id] }
    func currency(for cityID: String) -> String { cityByID[cityID]?.currency ?? "$" }

    func isWantToTry(_ id: String) -> Bool { wantToTryIDs.contains(id) }
    func isBeen(_ id: String) -> Bool { rankedRestaurantIDs.contains(id) }
    func ranking(for id: String) -> RankingEntry? { rankings.first { $0.restaurantID == id } }

    /// Taste match (0...1) between the current user and another user.
    func tasteMatch(_ other: User) -> Double { TasteMatch.score(currentUser, other) }

    // MARK: Intents — saving & visiting

    func toggleWantToTry(_ id: String) {
        if wantToTryIDs.contains(id) { wantToTryIDs.remove(id) }
        else {
            wantToTryIDs.insert(id)
            Haptics.tap()
        }
        persist()
    }

    /// Record a "Been" without ranking (ranking flow calls `applyRanking` afterward).
    func markVisited(_ id: String, tags: [QualityTag] = []) {
        guard !visits.contains(where: { $0.restaurantID == id }) else { return }
        visits.append(RestaurantVisit(id: "visit-\(id)-\(UUID().uuidString.prefix(6))",
                                      restaurantID: id, date: Date(), qualityTags: tags))
        wantToTryIDs.remove(id)
    }

    // MARK: Intents — friends & social

    func addFriend(_ id: String) {
        guard !friendIDs.contains(id) else { return }
        friendIDs.append(id)
        recomputeAchievements()
        persist()
    }

    func toggleLike(_ activityID: String) {
        guard let idx = feed.firstIndex(where: { $0.id == activityID }) else { return }
        if likedActivityIDs.contains(activityID) {
            likedActivityIDs.remove(activityID)
            feed[idx].likeCount = max(0, feed[idx].likeCount - 1)
            feed[idx].likedByCurrentUser = false
        } else {
            likedActivityIDs.insert(activityID)
            feed[idx].likeCount += 1
            feed[idx].likedByCurrentUser = true
            Haptics.tap()
        }
        persist()
    }

    func recordGroupRecommendation() {
        groupRecCount += 1
        if let idx = challenges.firstIndex(where: { $0.id == "c-friendsdinner" }) {
            challenges[idx].progress = min(challenges[idx].target, challenges[idx].progress + 1)
        }
        recomputeAchievements()
        persist()
    }

    // MARK: Achievements

    func progress(for achievementID: String) -> AchievementProgress? {
        achievementProgress[achievementID]
    }

    func isUnlocked(_ achievementID: String) -> Bool {
        achievementProgress[achievementID]?.isUnlocked ?? false
    }

    /// Feature up to 3 of the rarest unlocked achievements on the profile.
    func autoFeatureAchievements() {
        let unlocked = achievementsCatalog
            .filter { isUnlocked($0.id) }
            .sorted { $0.rarity > $1.rarity }
        featuredAchievementIDs = Array(unlocked.prefix(3).map(\.id))
        persist()
    }

    func setFeatured(_ ids: [String]) {
        featuredAchievementIDs = Array(ids.prefix(3))
        persist()
    }

    /// Rebuild achievement stats from live data, evaluate the catalog, and queue any
    /// newly-unlocked achievements for celebration.
    func recomputeAchievements(celebrate: Bool = true) {
        let stats = buildAchievementStats()
        let eval = achievementEngine.evaluate(
            catalog: achievementsCatalog,
            stats: stats,
            previouslyUnlocked: unlockedAchievements,
            now: Date()
        )
        achievementProgress = Dictionary(uniqueKeysWithValues: eval.progress.map { ($0.achievementID, $0) })

        // Persist unlock dates for anything newly crossed.
        for a in eval.newlyUnlocked where unlockedAchievements[a.id] == nil {
            unlockedAchievements[a.id] = achievementProgress[a.id]?.unlockedDate ?? Date()
        }
        if celebrate && !eval.newlyUnlocked.isEmpty {
            pendingUnlocks.append(contentsOf: eval.newlyUnlocked)
            Haptics.success()
        }
    }

    /// Assemble the live stats snapshot the achievement engine consumes.
    func buildAchievementStats() -> AchievementStats {
        var s = AchievementStats()
        let ranked = rankings.compactMap { restaurantByID[$0.restaurantID] }
        s.totalRanked = ranked.count
        for r in ranked {
            s.rankedByCity[r.cityID, default: 0] += 1
            if let c = cityByID[r.cityID] {
                s.countries.insert(c.country)
                s.cities.insert(c.id)
                if c.isAsian { s.asianCities.insert(c.id) }
            }
            s.neighborhoods.insert("\(r.cityID)|\(r.neighborhood)")
            s.neighborhoodsByCity[r.cityID, default: []].insert(r.neighborhood)
            if r.cuisine != .restaurant {
                s.cuisineFamilies.insert(r.cuisine.family)
                s.cuisineFamilyCounts[r.cuisine.family, default: 0] += 1
            }
            if r.isLandmark { s.landmarksVisited += 1 }
            if r.isMichelin { s.michelinVisited += 1 }
            // "Early discovery": user ranked a now-trending spot that was quiet early on.
            if r.isTrending && r.historicalCheckins < 200 { s.earlyDiscoveries += 1 }
        }
        s.friendCount = friendIDs.count
        s.pairwiseComparisons = comparisonCount
        s.groupRecommendations = groupRecCount
        s.bestFriendMatch = friends.map { tasteMatch($0) }.max() ?? 0
        let rankedIDs = rankedRestaurantIDs
        for c in collections {
            s.collectionTotal[c.id] = c.restaurantIDs.count
            s.collectionMatched[c.id] = c.restaurantIDs.filter { rankedIDs.contains($0) }.count
        }
        return s
    }

    func mergeListings(_ incoming: [Restaurant], cities incomingCities: [City]) {
        for r in incoming { restaurantByID[r.id] = r }
        // Keep personal places, but bound transient search data.
        let retained = rankedRestaurantIDs.union(wantToTryIDs).union(visits.map(\.restaurantID))
        let recent = restaurantByID.values.sorted { ($0.listing?.fetchedAt ?? .distantPast) > ($1.listing?.fetchedAt ?? .distantPast) }
        let keep = retained.union(recent.prefix(500).map(\.id))
        restaurantByID = restaurantByID.filter { keep.contains($0.key) }
        restaurants = restaurantByID.values.sorted { $0.name < $1.name }
        for c in incomingCities { cityByID[c.id] = c }
        cities = cityByID.values.sorted { $0.name < $1.name }
        persist()
    }
}
