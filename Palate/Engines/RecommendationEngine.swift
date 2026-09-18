import Foundation

/// Signal derived from one friend, precomputed by the store so the engine stays pure.
struct FriendSignal {
    let user: User
    let match: Double                       // taste match with current user, 0...1
    let topRankedRestaurantIDs: Set<String> // restaurants in this friend's personal top tier
    let wantToTryIDs: Set<String>
    /// Optional human scope label per restaurant, e.g. "#1 for Sichuan".
    let scopeLabels: [String: String]
}

/// Everything the engine needs to score candidates. Bundled so a real backend could
/// return the same shape from a network call.
struct RecommendationInput {
    let user: User
    let candidates: [Restaurant]
    let friends: [FriendSignal]
    let visitedRestaurantIDs: Set<String>
    let rankedCuisineFamilies: Set<String>   // families the user already has depth in
    let userLocation: Coordinate?
    let cityCurrency: (String) -> String     // cityID -> currency glyph
    let restaurantName: (String) -> String   // id -> name (for reasons)
}

/// Protocol so the mock engine can later be swapped for an ML/remote service.
protocol RecommendationProviding {
    func recommend(_ input: RecommendationInput, context: RecommendationContext?, limit: Int) -> [Recommendation]
}

/// Local, explainable recommendation engine.
///
/// RecommendationScore =
///   0.45·Taste + 0.25·Friend + 0.20·Context + 0.05·Popularity + 0.05·Novelty
///
/// The blend is intentionally taste-dominant, with friends (weighted by *their* taste
/// match) as the second-strongest voice — matching the product thesis: "your own taste
/// and people whose taste you trust."
struct RecommendationEngine: RecommendationProviding {

    // Component weights.
    private let wTaste = 0.45, wFriend = 0.25, wContext = 0.20, wPopularity = 0.05, wNovelty = 0.05

    func recommend(_ input: RecommendationInput, context: RecommendationContext? = nil, limit: Int = 20) -> [Recommendation] {
        input.candidates
            .map { score(restaurant: $0, input: input, context: context) }
            .sorted { $0.matchScore > $1.matchScore }
            .prefix(limit)
            .map { $0 }
    }

    /// Score a single restaurant and assemble its explanation.
    private func score(restaurant r: Restaurant, input: RecommendationInput, context: RecommendationContext?) -> Recommendation {
        let taste = tasteScore(user: input.user, restaurant: r)
        let (friend, supporters) = friendScore(restaurant: r, friends: input.friends)
        let ctx = contextScore(restaurant: r, context: context, userLocation: input.userLocation)
        let pop = r.popularity
        let novelty = noveltyScore(restaurant: r, input: input)

        let blended = wTaste * taste + wFriend * friend + wContext * ctx
                    + wPopularity * pop + wNovelty * novelty

        // Map the blend into a believable, well-spread match %. Aligned taste vectors
        // cluster high, so we stretch the mid-to-top band rather than showing raw cosine.
        let match = (0.42 + 0.58 * blended).clamped(to: 0...0.985)

        let breakdown = Recommendation.ScoreBreakdown(
            taste: taste, friend: friend, context: ctx, popularity: pop, novelty: novelty
        )
        let reasons = buildReasons(
            restaurant: r, input: input, context: context,
            taste: taste, supporters: supporters, novelty: novelty
        )
        return Recommendation(
            restaurantID: r.id, matchScore: match, breakdown: breakdown,
            reasons: reasons, supportingFriendIDs: supporters.map(\.user.id)
        )
    }

    // MARK: Components

    private func tasteScore(user: User, restaurant: Restaurant) -> Double {
        user.preferences.similarity(to: restaurant.attributes)
    }

    /// Weighted by each supporting friend's taste match (trusted friends count more).
    private func friendScore(restaurant: Restaurant, friends: [FriendSignal]) -> (Double, [FriendSignal]) {
        var supporters: [FriendSignal] = []
        var weightedSum = 0.0
        var weightTotal = 0.0
        for f in friends {
            weightTotal += f.match
            if f.topRankedRestaurantIDs.contains(restaurant.id) {
                weightedSum += f.match * 1.0
                supporters.append(f)
            } else if f.wantToTryIDs.contains(restaurant.id) {
                weightedSum += f.match * 0.4
                supporters.append(f)
            }
        }
        guard weightTotal > 0 else { return (0, []) }
        // Normalize against total friend trust so a couple of trusted friends move the needle.
        let raw = (weightedSum / weightTotal) * 2.2
        return (raw.clamped(to: 0...1), supporters.sorted { $0.match > $1.match })
    }

    /// Compatibility with the active dining request. Returns 0.5 (neutral) with no context.
    private func contextScore(restaurant: Restaurant, context: RecommendationContext?, userLocation: Coordinate?) -> Double {
        guard let ctx = context else { return 0.5 }
        var score = 0.5
        var considered = 0.0

        if let occ = ctx.occasion {
            considered += 1
            score += restaurant.occasions.contains(occ) ? 0.5 : -0.35
        }
        if let fam = ctx.cuisineFamily {
            considered += 1
            score += restaurant.cuisine.family == fam ? 0.5 : -0.5
        }
        if let maxPrice = ctx.maxPrice {
            considered += 1
            score += restaurant.price <= maxPrice ? 0.3 : -0.6
        }
        if let hood = ctx.neighborhood {
            considered += 1
            score += restaurant.neighborhood == hood ? 0.4 : -0.2
        }
        if let upscale = ctx.upscale {
            considered += 1
            let isUpscale = restaurant.price >= .upscale || restaurant.attributes[.fineDining] > 0.6
            score += (isUpscale == upscale) ? 0.25 : -0.2
        }
        if let maxKm = ctx.maxDistanceKm, let loc = userLocation {
            considered += 1
            let d = restaurant.coordinate.distance(to: loc)
            score += d <= maxKm ? 0.3 : -0.5
        }
        // With no active filters, stay neutral so taste dominates.
        return considered == 0 ? 0.5 : score.clamped(to: 0...1)
    }

    /// Rewards genuinely new experiences: unvisited + (new cuisine family or ahead-of-trend).
    private func noveltyScore(restaurant: Restaurant, input: RecommendationInput) -> Double {
        if input.visitedRestaurantIDs.contains(restaurant.id) { return 0.05 }
        var score = 0.4
        if !input.rankedCuisineFamilies.contains(restaurant.cuisine.family) { score += 0.35 }
        if restaurant.historicalCheckins < 120 && !restaurant.isTrending { score += 0.2 } // undiscovered gem
        return score.clamped(to: 0...1)
    }

    // MARK: Reasons

    private func buildReasons(restaurant r: Restaurant, input: RecommendationInput,
                              context: RecommendationContext?, taste: Double,
                              supporters: [FriendSignal], novelty: Double) -> [String] {
        var reasons: [String] = []

        // 1) Taste — call out the strongest shared dimension.
        if let dim = strongestSharedDimension(user: input.user, restaurant: r) {
            reasons.append(tasteReason(for: dim, cuisine: r.cuisine))
        }

        // 2) Friend — cite the single most-trusted supporter.
        if let f = supporters.first {
            if let scope = f.scopeLabels[r.id] {
                reasons.append("\(f.user.name), a \(f.match.asPercent) taste match, ranks it \(scope).")
            } else if f.topRankedRestaurantIDs.contains(r.id) {
                reasons.append("\(f.user.name), a \(f.match.asPercent) taste match, loves it.")
            } else {
                reasons.append("\(f.user.name) (\(f.match.asPercent) taste match) wants to try it too.")
            }
        }

        // 3) Context — price / occasion / distance.
        if let ctx = context {
            if let maxPrice = ctx.maxPrice, r.price <= maxPrice {
                reasons.append("Within your usual price range.")
            }
            if let occ = ctx.occasion, r.occasions.contains(occ) {
                reasons.append("A great pick for \(occ.label.lowercased()).")
            }
            if let loc = input.userLocation {
                let minutes = max(2, Int(r.coordinate.distance(to: loc) * 3))
                if minutes <= 25 { reasons.append("About \(minutes) minutes away.") }
            }
        }

        // 4) Novelty / discovery.
        if novelty > 0.7 && !input.rankedCuisineFamilies.contains(r.cuisine.family) {
            reasons.append("A cuisine you haven't explored much yet.")
        } else if r.historicalCheckins < 120 && !r.isTrending {
            reasons.append("A hidden gem before the crowds find it.")
        }

        // Always guarantee at least one reason.
        if reasons.isEmpty {
            reasons.append(r.isMichelin ? "A celebrated \(r.cuisine.label.lowercased()) destination."
                                        : "Highly aligned with your taste profile.")
        }
        return Array(reasons.prefix(4))
    }

    /// The dimension where user preference and restaurant attribute are both high.
    private func strongestSharedDimension(user: User, restaurant: Restaurant) -> TasteDimension? {
        TasteDimension.allCases
            .map { ($0, user.preferences[$0] * restaurant.attributes[$0]) }
            .filter { $0.1 > 0.25 }
            .max { $0.1 < $1.1 }?.0
    }

    private func tasteReason(for dim: TasteDimension, cuisine: Cuisine) -> String {
        switch dim {
        case .sichuan: return "Matches your love of bold Sichuan flavor."
        case .chinese: return "Matches your preference for creative Chinese cuisine."
        case .japanese: return "You gravitate toward Japanese cooking."
        case .korean: return "Right in your Korean-food wheelhouse."
        case .novelty: return "Inventive cooking, which you seek out."
        case .authenticity: return "Deeply authentic — the way you like it."
        case .atmosphere: return "The kind of room you love to linger in."
        case .value: return "Strong value, which matters to you."
        case .fineDining: return "A refined experience that fits your taste."
        case .spicy: return "Brings the heat you look for."
        case .coffee: return "A café that fits your coffee habit."
        case .dessert: return "Scratches your sweet tooth."
        case .streetFood: return "Great casual, street-style eating."
        default: return "Closely matches your \(cuisine.family) taste."
        }
    }
}
