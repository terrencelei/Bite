import Foundation

// MARK: - Friend signals & recommendations

@MainActor
extension AppModel {

    /// Build per-friend signals for the recommender from the mock friend data.
    func friendSignals() -> [FriendSignal] {
        friends.map { friend in
            FriendSignal(
                user: friend,
                match: tasteMatch(friend),
                topRankedRestaurantIDs: Set(SeedData.friendTopPicks[friend.id] ?? []),
                wantToTryIDs: Set(SeedData.friendWantToTry[friend.id] ?? []),
                scopeLabels: SeedData.friendScopeLabels[friend.id] ?? [:]
            )
        }
    }

    private func makeInput(candidates: [Restaurant]) -> RecommendationInput {
        let rankedFamilies = Set(rankings.compactMap { restaurantByID[$0.restaurantID]?.cuisine.family })
        let home = cityByID[homeCityID]?.center
        return RecommendationInput(
            user: currentUser,
            candidates: candidates,
            friends: friendSignals(),
            visitedRestaurantIDs: Set(visits.map(\.restaurantID)),
            rankedCuisineFamilies: rankedFamilies,
            userLocation: home,
            cityCurrency: { [weak self] cid in self?.currency(for: cid) ?? "$" },
            restaurantName: { [weak self] rid in self?.restaurantByID[rid]?.name ?? "" }
        )
    }

    /// Core recommendation call. Excludes already-visited restaurants by default.
    func recommendations(context: RecommendationContext? = nil,
                         candidates: [Restaurant]? = nil,
                         excludeVisited: Bool = true,
                         limit: Int = 20) -> [Recommendation] {
        var pool = candidates ?? restaurants
        if excludeVisited {
            let visited = Set(visits.map(\.restaurantID))
            pool = pool.filter { !visited.contains($0.id) }
        }
        return recommender.recommend(makeInput(candidates: pool), context: context, limit: limit)
    }

    /// A single restaurant's personalized match + reasons (for detail screens & cards).
    func recommendation(for id: String, context: RecommendationContext? = nil) -> Recommendation? {
        guard let r = restaurantByID[id] else { return nil }
        return recommender.recommend(makeInput(candidates: [r]), context: context, limit: 1).first
    }

    // MARK: Taste twins

    /// Friends sorted by taste match, highest first.
    func tasteTwins() -> [(user: User, match: Double)] {
        friends.map { ($0, tasteMatch($0)) }.sorted { $0.1 > $1.1 }
    }

    /// Friends who have ranked/ want-to-try a given restaurant (for detail friend rows).
    func friendsWithActivity(for restaurantID: String) -> [(user: User, label: String)] {
        friends.compactMap { friend in
            if let scope = SeedData.friendScopeLabels[friend.id]?[restaurantID] {
                return (friend, "ranks it \(scope)")
            }
            if SeedData.friendTopPicks[friend.id]?.contains(restaurantID) == true {
                return (friend, "has it in their top picks")
            }
            if SeedData.friendWantToTry[friend.id]?.contains(restaurantID) == true {
                return (friend, "wants to try it")
            }
            return nil
        }
    }
}

// MARK: - Ranking scopes & leaderboards

/// A named ranking list (overall, a city, a cuisine, an occasion, a price band).
struct RankingScope: Identifiable, Hashable {
    enum Kind: Hashable {
        case overall
        case city(String)
        case cuisine(String)
        case occasion(Occasion)
        case priceUnder(PriceLevel)
    }
    let kind: Kind
    let title: String
    let subtitle: String
    let symbol: String
    var id: String { title }
}

@MainActor
extension AppModel {

    /// 1-based rank of an entry within the overall list (by latent score).
    func overallRank(of entry: RankingEntry) -> Int? {
        let sorted = rankings.sorted { $0.score > $1.score }
        return sorted.firstIndex(where: { $0.id == entry.id }).map { $0 + 1 }
    }

    /// 1-based rank of a restaurant within a given scope.
    func rank(of restaurantID: String, in scope: RankingScope) -> Int? {
        entries(in: scope).firstIndex { $0.restaurant.id == restaurantID }.map { $0 + 1 }
    }

    /// Entries in a scope, sorted best-first, resolved to restaurants.
    func entries(in scope: RankingScope) -> [(entry: RankingEntry, restaurant: Restaurant)] {
        rankings
            .compactMap { e -> (RankingEntry, Restaurant)? in
                guard let r = restaurantByID[e.restaurantID] else { return nil }
                return matches(restaurant: r, scope: scope.kind) ? (e, r) : nil
            }
            .sorted { $0.0.score > $1.0.score }
            .map { (entry: $0.0, restaurant: $0.1) }
    }

    private func matches(restaurant r: Restaurant, scope: RankingScope.Kind) -> Bool {
        switch scope {
        case .overall: return true
        case .city(let id): return r.cityID == id
        case .cuisine(let fam): return r.cuisine.family == fam
        case .occasion(let occ): return r.occasions.contains(occ)
        case .priceUnder(let p): return r.price <= p
        }
    }

    /// The scopes worth surfacing, given what the user has actually ranked.
    func availableScopes() -> [RankingScope] {
        var scopes: [RankingScope] = [
            RankingScope(kind: .overall, title: "My Top Restaurants",
                         subtitle: "Everywhere you've ranked", symbol: "trophy.fill")
        ]
        // Cities with ≥1 ranked restaurant.
        for c in cities where entries(in: RankingScope(kind: .city(c.id), title: c.name, subtitle: "", symbol: "")).isEmpty == false {
            scopes.append(RankingScope(kind: .city(c.id), title: c.name,
                                       subtitle: "\(c.countryFlag) \(c.country)", symbol: "mappin.circle.fill"))
        }
        // Cuisine families with ≥2 ranked.
        let familyCounts = Dictionary(grouping: rankings.compactMap { restaurantByID[$0.restaurantID]?.cuisine.family }, by: { $0 })
            .mapValues(\.count)
        for (fam, count) in familyCounts.sorted(by: { $0.value > $1.value }) where count >= 2 {
            scopes.append(RankingScope(kind: .cuisine(fam), title: fam,
                                       subtitle: "Your \(fam.lowercased()) ranking", symbol: "fork.knife"))
        }
        // A couple of occasion + value lists if populated.
        for occ in [Occasion.dateNight, .cheapEats] {
            if !entries(in: RankingScope(kind: .occasion(occ), title: "", subtitle: "", symbol: "")).isEmpty {
                scopes.append(RankingScope(kind: .occasion(occ), title: occ.label,
                                           subtitle: "Best for \(occ.label.lowercased())", symbol: occ.symbol))
            }
        }
        return scopes
    }

    // MARK: Applying a ranking

    /// Prepare a ranking session comparing `restaurantID` against existing entries in
    /// its home-city scope (the most meaningful comparison set).
    func makeRankingSession(for restaurantID: String) -> RankingSession {
        guard let r = restaurantByID[restaurantID] else {
            return RankingSession(newRestaurantID: restaurantID, scopeName: "Overall", existing: [])
        }
        let cityScope = RankingScope(kind: .city(r.cityID), title: "", subtitle: "", symbol: "")
        let existing = entries(in: cityScope).map(\.entry)
        return RankingSession(newRestaurantID: restaurantID,
                              scopeName: cityByID[r.cityID]?.name ?? "Overall",
                              existing: existing)
    }

    /// Commit a finished ranking session: insert the entry, update compared scores,
    /// nudge the taste model, advance challenges, add a feed post, and re-run achievements.
    @discardableResult
    func applyRanking(session: RankingSession, tags: [QualityTag]) -> RankingEntry {
        let rid = session.newRestaurantID
        markVisited(rid, tags: tags)

        // Clear any prior "NEW" flags, then insert/replace this entry as NEW.
        for i in rankings.indices { rankings[i].isNew = false }
        rankings.removeAll { $0.restaurantID == rid }
        let entry = RankingEntry(id: "rank-\(rid)", restaurantID: rid,
                                 score: session.resultScore, comparisons: session.comparisonsMade,
                                 dateRanked: Date(), isNew: true)
        rankings.append(entry)

        // Bradley-Terry style nudges to the restaurants that were actually compared.
        for outcome in session.outcomes {
            applyComparisonUpdate(winnerID: outcome.winnerID, loserID: outcome.loserID)
        }
        comparisonCount += session.outcomes.count

        // Online taste learning: drift toward what we just ranked, reinforce tagged axes.
        if let r = restaurantByID[rid] {
            currentUser.preferences.nudge(toward: r.attributes, rate: 0.08)
            let tagDims = tags.flatMap { $0.dimensions }
            currentUser.preferences.reinforce(tagDims, by: 0.03)
            advanceChallengesAfterRanking(restaurant: r)
            prependFeedRanking(for: r)
        }

        recomputeAchievements(celebrate: true)
        persist()
        return entry
    }

    private func applyComparisonUpdate(winnerID: String, loserID: String) {
        guard let wi = rankings.firstIndex(where: { $0.restaurantID == winnerID }),
              let li = rankings.firstIndex(where: { $0.restaurantID == loserID }) else { return }
        let (w, l) = RankingEngine.updatedScore(winner: rankings[wi].score, loser: rankings[li].score)
        rankings[wi].score = w
        rankings[li].score = l
    }

    private func advanceChallengesAfterRanking(restaurant r: Restaurant) {
        // New-neighborhood challenge.
        let hoodsBefore = Set(rankings.dropLast().compactMap { restaurantByID[$0.restaurantID].map { "\($0.cityID)|\($0.neighborhood)" } })
        if !hoodsBefore.contains("\(r.cityID)|\(r.neighborhood)"),
           let i = challenges.firstIndex(where: { $0.id == "c-newhoods" }) {
            challenges[i].progress = min(challenges[i].target, challenges[i].progress + 1)
        }
        // Shanghai-this-month challenge.
        if r.cityID == "shanghai", let i = challenges.firstIndex(where: { $0.id == "c-shmonth" }) {
            challenges[i].progress = min(challenges[i].target, challenges[i].progress + 1)
        }
    }

    private func prependFeedRanking(for r: Restaurant) {
        let scope = cityByID[r.cityID]?.name ?? "your list"
        let position = (entries(in: RankingScope(kind: .city(r.cityID), title: "", subtitle: "", symbol: ""))
            .firstIndex { $0.restaurant.id == r.id } ?? 0) + 1
        let activity = SocialActivity(
            id: "self-\(r.id)-\(UUID().uuidString.prefix(4))",
            userID: currentUser.id,
            kind: .ranked(restaurantID: r.id, position: position, scope: scope),
            date: Date(), likeCount: 0, commentCount: 0
        )
        feed.insert(activity, at: 0)
    }
}

// MARK: - Group recommendations

@MainActor
extension AppModel {
    func groupRecommendations(request: GroupRequest) -> [GroupPick] {
        let members = request.memberIDs.compactMap { userByID[$0] }
        return groupEngine.recommend(members: members, candidates: restaurants, request: request)
    }
}

// MARK: - Food passport & city completion

/// One country block in the Food Passport.
struct PassportCountry: Identifiable, Hashable {
    let country: String
    let flag: String
    let cities: [PassportCity]
    var id: String { country }
    var total: Int { cities.reduce(0) { $0 + $1.count } }
}

struct PassportCity: Identifiable, Hashable {
    let cityID: String
    let name: String
    let count: Int
    var id: String { cityID }
}

@MainActor
extension AppModel {

    /// Build the Food Passport grouped by country → city, counting ranked restaurants.
    func passport() -> [PassportCountry] {
        var byCity: [String: Int] = [:]
        for e in rankings { if let r = restaurantByID[e.restaurantID] { byCity[r.cityID, default: 0] += 1 } }

        let grouped = Dictionary(grouping: cities.filter { (byCity[$0.id] ?? 0) > 0 }, by: { $0.country })
        return grouped.map { country, cs in
            let flag = cs.first?.countryFlag ?? "🏳️"
            let pcs = cs.map { PassportCity(cityID: $0.id, name: $0.name, count: byCity[$0.id] ?? 0) }
                .sorted { $0.count > $1.count }
            return PassportCountry(country: country, flag: flag, cities: pcs)
        }
        .sorted { $0.total > $1.total }
    }

    /// Per-neighborhood completion for a city (ranked vs. total restaurants present).
    func cityCompletion(_ cityID: String) -> [(neighborhood: String, ranked: Int, total: Int)] {
        guard let city = cityByID[cityID] else { return [] }
        let cityRestaurants = restaurants.filter { $0.cityID == cityID }
        let rankedIDs = rankedRestaurantIDs
        return city.neighborhoods.map { hood in
            let inHood = cityRestaurants.filter { $0.neighborhood == hood }
            let ranked = inHood.filter { rankedIDs.contains($0.id) }.count
            return (hood, ranked, inHood.count)
        }
        .filter { $0.total > 0 }
        .sorted { ($0.ranked == $0.total ? 0 : 1, $0.neighborhood) < ($1.ranked == $1.total ? 0 : 1, $1.neighborhood) }
    }

    // MARK: Discover sections

    /// A personalized Discover shelf.
    struct DiscoverSection: Identifiable {
        let id: String
        let title: String
        var subtitle: String?
        let recommendations: [Recommendation]
    }

    /// Build the personalized Discover feed. One recommendation pass feeds every shelf,
    /// so match scores stay consistent across sections.
    func discoverSections() -> [DiscoverSection] {
        let recs = recommendations(limit: 60)                    // excludes visited
        let byID = Dictionary(uniqueKeysWithValues: recs.map { ($0.restaurantID, $0) })
        func rec(_ id: String) -> Recommendation? { byID[id] }
        func restaurant(_ r: Recommendation) -> Restaurant? { restaurantByID[r.restaurantID] }

        var sections: [DiscoverSection] = []

        // Perfect for You — the strongest overall matches.
        sections.append(DiscoverSection(id: "perfect", title: "Perfect for You",
                                        subtitle: "Your strongest matches right now",
                                        recommendations: Array(recs.prefix(8))))

        // Because You Loved … — anchored on the user's current #1 ranked restaurant.
        if let topEntry = rankings.max(by: { $0.score < $1.score }),
           let anchor = restaurantByID[topEntry.restaurantID] {
            let similar = recs.filter { restaurant($0)?.cuisine.family == anchor.cuisine.family }
            if !similar.isEmpty {
                sections.append(DiscoverSection(id: "becauseLoved",
                                                title: "Because You Loved \(anchor.name)",
                                                subtitle: "More \(anchor.cuisine.family.lowercased()) you'll like",
                                                recommendations: Array(similar.prefix(8))))
            }
        }

        // Friends Are Loving — friend-backed picks.
        let friendBacked = recs.filter { !$0.supportingFriendIDs.isEmpty }
        if !friendBacked.isEmpty {
            sections.append(DiscoverSection(id: "friends", title: "Friends Are Loving",
                                            subtitle: "Loved by people whose taste you trust",
                                            recommendations: Array(friendBacked.prefix(8))))
        }

        // Trending With Your Taste.
        let trending = recs.filter { restaurant($0)?.isTrending == true }
        if !trending.isEmpty {
            sections.append(DiscoverSection(id: "trending", title: "Trending With Your Taste",
                                            subtitle: "On the rise, and up your alley",
                                            recommendations: Array(trending.prefix(8))))
        }

        // Hidden Gems — under-the-radar spots with a strong match.
        let gems = recs.filter { r in
            guard let rr = restaurant(r) else { return false }
            return rr.historicalCheckins < 160 && !rr.isTrending
        }
        if !gems.isEmpty {
            sections.append(DiscoverSection(id: "gems", title: "Hidden Gems",
                                            subtitle: "Before the crowds find them",
                                            recommendations: Array(gems.prefix(8))))
        }

        // Near You — home city.
        let near = recs.filter { restaurant($0)?.cityID == homeCityID }
        if !near.isEmpty {
            sections.append(DiscoverSection(id: "near", title: "Near You",
                                            subtitle: cityByID[homeCityID]?.name,
                                            recommendations: Array(near.prefix(8))))
        }

        // Try Something New — cuisine families the user hasn't ranked yet.
        let rankedFamilies = Set(rankings.compactMap { restaurantByID[$0.restaurantID]?.cuisine.family })
        let novel = recs.filter { r in
            guard let rr = restaurant(r) else { return false }
            return !rankedFamilies.contains(rr.cuisine.family)
        }
        if !novel.isEmpty {
            sections.append(DiscoverSection(id: "new", title: "Try Something New",
                                            subtitle: "Cuisines you haven't explored",
                                            recommendations: Array(novel.prefix(8))))
        }

        return sections
    }

    /// The ranked restaurants that count toward a given achievement (for its detail page).
    func restaurantsContributing(to achievement: Achievement) -> [Restaurant] {
        let ranked = rankings.compactMap { restaurantByID[$0.restaurantID] }
        switch achievement.requirement {
        case .cityRestaurantCount(let cityID, _):
            return ranked.filter { $0.cityID == cityID }
        case .specificCuisineCount(let family, _):
            return ranked.filter { $0.cuisine.family == family }
        case .landmarkRestaurantCount:
            return ranked.filter { $0.isLandmark }
        case .michelinCount:
            return ranked.filter { $0.isMichelin }
        case .earlyDiscoveryCount:
            return ranked.filter { $0.isTrending && $0.historicalCheckins < 200 }
        case .collectionCompleted(let id):
            let ids = Set(collections.first { $0.id == id }?.restaurantIDs ?? [])
            return ranked.filter { ids.contains($0.id) }
        case .restaurantCount, .cuisineCount, .neighborhoodCount:
            return Array(ranked.prefix(8))
        default:
            return []
        }
    }

    /// Achievements closest to unlocking (for the "Almost There" module), unlocked excluded.
    func almostThere(limit: Int = 4) -> [(achievement: Achievement, progress: AchievementProgress)] {
        achievementsCatalog
            .compactMap { a -> (Achievement, AchievementProgress)? in
                guard let p = achievementProgress[a.id], !p.isUnlocked, p.current > 0 else { return nil }
                return (a, p)
            }
            .sorted { $0.1.fraction > $1.1.fraction }
            .prefix(limit)
            .map { (achievement: $0.0, progress: $0.1) }
    }
}
