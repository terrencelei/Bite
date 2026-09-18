import Foundation

/// Computes taste similarity between users. Kept separate so it can be reused by
/// recommendations, friend profiles, taste twins, and group scoring.
enum TasteMatch {

    /// Similarity between two users in 0...1.
    ///
    /// Raw cosine over non-negative preference vectors clusters very high (~0.9–1.0),
    /// which would make everyone look like a 99% match. We stretch the meaningful band
    /// [0.85, 1.0] across [0.70, 0.98] so taste-match reads with believable spread and
    /// never hits a suspicious literal 100%.
    static func score(_ a: User, _ b: User) -> Double {
        let raw = a.preferences.similarity(to: b.preferences)
        let stretched = 0.70 + ((raw - 0.85) / 0.15).clamped(to: 0...1) * 0.28
        return stretched.clamped(to: 0...0.98)
    }

    /// Dimensions where both users score highly — "taste in common".
    static func commonStrengths(_ a: User, _ b: User, minimum: Double = 0.6) -> [TasteDimension] {
        TasteDimension.allCases
            .filter { a.preferences[$0] >= minimum && b.preferences[$0] >= minimum }
            .sorted { (a.preferences[$0] + b.preferences[$0]) > (a.preferences[$1] + b.preferences[$1]) }
    }

    /// Dimensions where the two users most disagree — "where you disagree".
    static func disagreements(_ a: User, _ b: User, minimumGap: Double = 0.35) -> [(dimension: TasteDimension, higher: String)] {
        TasteDimension.allCases.compactMap { dim in
            let gap = abs(a.preferences[dim] - b.preferences[dim])
            guard gap >= minimumGap else { return nil }
            let higher = a.preferences[dim] > b.preferences[dim] ? a.name : b.name
            return (dim, higher)
        }
        .sorted { abs(a.preferences[$0.dimension] - b.preferences[$0.dimension]) >
                  abs(a.preferences[$1.dimension] - b.preferences[$1.dimension]) }
    }
}
