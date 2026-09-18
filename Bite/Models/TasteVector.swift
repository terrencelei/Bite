import Foundation

/// A point in the shared taste space. Wraps a dictionary keyed by `TasteDimension`
/// so callers can read/write named axes, while exposing a dense `[Double]` for math.
struct TasteVector: Codable, Hashable {
    private(set) var values: [TasteDimension: Double]

    init(_ values: [TasteDimension: Double] = [:]) {
        // Default any missing dimension to a neutral 0.
        var filled: [TasteDimension: Double] = [:]
        for dim in TasteDimension.allCases {
            filled[dim] = (values[dim] ?? 0).clamped(to: 0...1)
        }
        self.values = filled
    }

    subscript(_ dim: TasteDimension) -> Double {
        get { values[dim] ?? 0 }
        set { values[dim] = newValue.clamped(to: 0...1) }
    }

    /// Dense representation in the canonical dimension order (for similarity math).
    var dense: [Double] {
        TasteDimension.allCases.map { values[$0] ?? 0 }
    }

    /// Cosine similarity with another vector, in 0...1.
    func similarity(to other: TasteVector) -> Double {
        dense.cosineSimilarity(with: other.dense)
    }

    /// The user's strongest dimensions, most-preferred first.
    func topDimensions(_ count: Int = 4) -> [TasteDimension] {
        values.sorted { $0.value > $1.value }.prefix(count).map(\.key)
    }

    /// Move this vector a small step toward a target — the core of online taste learning.
    /// `rate` controls how quickly preferences drift (kept low so taste feels stable).
    mutating func nudge(toward target: TasteVector, rate: Double) {
        for dim in TasteDimension.allCases {
            let current = values[dim] ?? 0
            let goal = target[dim]
            values[dim] = (current + (goal - current) * rate).clamped(to: 0...1)
        }
    }

    /// Reinforce specific dimensions (e.g. after a "what made it better?" tag).
    mutating func reinforce(_ dims: [TasteDimension], by amount: Double) {
        for dim in dims {
            values[dim] = ((values[dim] ?? 0) + amount).clamped(to: 0...1)
        }
    }

    /// Average of several vectors — used to seed group taste.
    static func average(_ vectors: [TasteVector]) -> TasteVector {
        guard !vectors.isEmpty else { return TasteVector() }
        var acc: [TasteDimension: Double] = [:]
        for v in vectors {
            for dim in TasteDimension.allCases { acc[dim, default: 0] += v[dim] }
        }
        for dim in TasteDimension.allCases { acc[dim]? /= Double(vectors.count) }
        return TasteVector(acc)
    }
}
