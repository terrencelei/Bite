import SwiftUI

// MARK: - Deterministic color seeding

extension Color {
    /// Builds a stable, pleasant color from any string seed.
    /// Used so every restaurant/user gets a consistent identity color offline.
    static func seeded(_ seed: String, saturation: Double = 0.55, brightness: Double = 0.80) -> Color {
        let hash = seed.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    /// A two-stop gradient seeded from a string — the basis of procedural food placeholders.
    static func seededPair(_ seed: String) -> (Color, Color) {
        let hash = seed.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        let hue = Double(hash % 360) / 360.0
        let hue2 = (hue + 0.08).truncatingRemainder(dividingBy: 1.0)
        return (
            Color(hue: hue, saturation: 0.62, brightness: 0.78),
            Color(hue: hue2, saturation: 0.72, brightness: 0.55)
        )
    }
}

// MARK: - Numeric helpers

extension Double {
    /// Clamp into a closed range.
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// Render as a whole-number percentage, e.g. 0.936 -> "94%".
    var asPercent: String {
        "\(Int((self * 100).rounded()))%"
    }
}

extension Array where Element == Double {
    /// Cosine similarity between two equal-length vectors, mapped into 0...1.
    func cosineSimilarity(with other: [Double]) -> Double {
        guard count == other.count, !isEmpty else { return 0 }
        var dot = 0.0, magA = 0.0, magB = 0.0
        for i in indices {
            dot += self[i] * other[i]
            magA += self[i] * self[i]
            magB += other[i] * other[i]
        }
        guard magA > 0, magB > 0 else { return 0 }
        let cos = dot / (magA.squareRoot() * magB.squareRoot())
        // Cosine of non-negative vectors is already in 0...1, but clamp for safety.
        return cos.clamped(to: 0...1)
    }
}

// MARK: - Collection safety

extension Collection {
    /// Safe indexing that returns nil instead of trapping.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Date helpers

extension Date {
    var relativeShort: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: self, relativeTo: Date())
    }
}
