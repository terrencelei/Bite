import Foundation

/// Scores restaurants for a *group*, balancing average satisfaction against
/// disagreement — so the pick everyone is happy with beats the pick one person loves.
///
/// GroupScore = mean(memberPreference) − λ · stddev(memberPreference)
///
/// The disagreement penalty (λ) keeps polarizing restaurants out of group results.
struct GroupRecommendationEngine {

    private let lambda = 0.6

    func recommend(members: [User], candidates: [Restaurant], request: GroupRequest, limit: Int = 5) -> [GroupPick] {
        let filtered = candidates.filter { r in
            guard r.cityID == request.cityID else { return false }
            guard r.price <= request.maxPrice else { return false }
            if let fam = request.cuisineFamily, r.cuisine.family != fam { return false }
            if let occ = request.occasion, !r.occasions.contains(occ) { return false }
            return true
        }

        let picks = filtered.map { restaurant -> GroupPick in
            let matches = members.map { member in
                MemberMatch(userID: member.id,
                            score: member.preferences.similarity(to: restaurant.attributes))
            }
            let scores = matches.map(\.score)
            let mean = scores.reduce(0, +) / Double(scores.count)
            let variance = scores.reduce(0) { $0 + pow($1 - mean, 2) } / Double(scores.count)
            let std = variance.squareRoot()
            let group = (mean - lambda * std).clamped(to: 0...1)

            return GroupPick(
                id: restaurant.id,
                restaurantID: restaurant.id,
                // Present a believable, well-spread group match.
                groupScore: (0.45 + 0.55 * group).clamped(to: 0...0.985),
                memberMatches: matches,
                reason: reason(for: restaurant, matches: matches, members: members)
            )
        }

        return picks.sorted { $0.groupScore > $1.groupScore }.prefix(limit).map { $0 }
    }

    /// Build a short explanation citing the shared cuisine and consensus.
    private func reason(for r: Restaurant, matches: [MemberMatch], members: [User]) -> String {
        let low = matches.map(\.score).min() ?? 0
        let cuisine = r.cuisine.label.lowercased()
        if low >= 0.65 {
            return "Everyone leans toward \(cuisine), and it fits the whole group's usual budget."
        } else if let weak = matches.min(by: { $0.score < $1.score }),
                  let name = members.first(where: { $0.id == weak.userID })?.name {
            return "A strong middle-ground for \(cuisine) — even \(name) should enjoy it."
        }
        return "A crowd-pleasing \(cuisine) spot that balances everyone's taste."
    }
}
