import Foundation

/// An optional, low-pressure exploration challenge. Deliberately *never* requires
/// spending money or visiting expensive restaurants, and has no punishing streaks.
struct Challenge: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let target: Int
    var progress: Int
    /// A soft, optional timeframe label ("This month") — purely cosmetic.
    var timeframe: String?

    var fraction: Double { target <= 0 ? 0 : min(1, Double(progress) / Double(target)) }
    var isComplete: Bool { progress >= target }
}
