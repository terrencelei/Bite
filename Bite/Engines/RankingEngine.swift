import Foundation
import Observation

/// Pure placement math for the ranking system.
///
/// We use a binary-search placement (which keeps the number of A/B questions to
/// ~log₂n and feels snappy) layered with a Bradley-Terry-style latent score so the
/// leaderboard has smooth, comparable strengths rather than raw ordinal ranks.
enum RankingEngine {

    /// Latent score handed to the very first restaurant a user ranks.
    static let seedScore: Double = 50

    /// Interpolate a latent score for a restaurant inserted at `index` within a
    /// descending-by-score list of existing entries.
    static func interpolatedScore(insertingAt index: Int, into sorted: [RankingEntry]) -> Double {
        guard !sorted.isEmpty else { return seedScore }
        let upper = index > 0 ? sorted[index - 1].score : sorted.first!.score + 8
        let lower = index < sorted.count ? sorted[index].score : sorted.last!.score - 8
        return (upper + lower) / 2
    }

    /// Bradley-Terry style online update applied to compared entries for realism:
    /// the winner drifts up, the loser drifts down, scaled by surprise.
    static func updatedScore(winner: Double, loser: Double, k: Double = 1.5) -> (Double, Double) {
        // Probability the winner was expected to win (logistic over score gap / 10).
        let expected = 1.0 / (1.0 + pow(10, (loser - winner) / 10))
        let delta = k * (1 - expected)
        return (winner + delta, loser - delta)
    }
}

/// Drives the interactive pairwise ranking flow for one restaurant.
///
/// Lifecycle: create with the restaurant being ranked and the existing ranked entries
/// in the same scope (e.g. same city). The view repeatedly reads `currentOpponentID`
/// and calls `choose(preferredNew:)`. When `isFinished` flips true, read
/// `resultIndex` / `resultScore` to insert into the leaderboard.
@Observable
final class RankingSession {
    let newRestaurantID: String
    let scopeName: String
    /// Existing entries in this scope, sorted best-first (rank 1 == index 0).
    let sorted: [RankingEntry]

    private var lo = 0
    private var hi: Int
    private(set) var comparisonsMade = 0
    let maxComparisons: Int

    private(set) var isFinished = false
    private(set) var resultIndex = 0
    private(set) var resultScore = RankingEngine.seedScore

    /// History of comparisons the user resolved (for achievements + score updates).
    private(set) var outcomes: [(winnerID: String, loserID: String)] = []

    init(newRestaurantID: String, scopeName: String, existing: [RankingEntry]) {
        self.newRestaurantID = newRestaurantID
        self.scopeName = scopeName
        self.sorted = existing
        self.hi = existing.count
        // ~log2(n) questions, clamped to a friendly 1...5 for the demo.
        let ideal = Int(ceil(log2(Double(existing.count + 1))))
        self.maxComparisons = min(5, max(1, ideal))

        if existing.isEmpty {
            finish(at: 0)
        }
    }

    /// The opponent restaurant currently being compared, or nil when finished.
    var currentOpponentID: String? {
        guard !isFinished, lo < hi else { return nil }
        let mid = (lo + hi) / 2
        return sorted[safe: mid]?.restaurantID
    }

    /// Fraction of the flow completed, for a progress indicator.
    var progress: Double {
        guard maxComparisons > 0 else { return 1 }
        return min(1, Double(comparisonsMade) / Double(maxComparisons))
    }

    /// Record the user's choice. `preferredNew` == they liked the new restaurant more.
    func choose(preferredNew: Bool) {
        guard !isFinished, lo < hi else { return }
        let mid = (lo + hi) / 2
        if let opponentID = sorted[safe: mid]?.restaurantID {
            if preferredNew {
                outcomes.append((newRestaurantID, opponentID))
                hi = mid                 // new ranks higher → search upper (lower index) half
            } else {
                outcomes.append((opponentID, newRestaurantID))
                lo = mid + 1             // new ranks lower → search lower half
            }
        }
        comparisonsMade += 1

        if lo >= hi || comparisonsMade >= maxComparisons {
            finish(at: lo)
        }
    }

    private func finish(at index: Int) {
        resultIndex = min(index, sorted.count)
        resultScore = RankingEngine.interpolatedScore(insertingAt: resultIndex, into: sorted)
        isFinished = true
    }
}
