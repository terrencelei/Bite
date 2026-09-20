import Foundation

/// A dish suggestion shown on restaurant detail.
struct Dish: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let note: String
    /// Optional "signature" flag for visual emphasis.
    var isSignature: Bool = false
}

/// The central content object. Its `attributes` vector places it in the shared taste
/// space; the recommendation engine scores users/friends against it.
struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let cuisine: Cuisine
    let subCuisine: String
    let cityID: String
    let neighborhood: String
    let price: PriceLevel
    let coordinate: Coordinate

    /// Attribute embedding in taste space (0...1 per dimension).
    let attributes: TasteVector
    /// Occasions this restaurant suits well.
    let occasions: Set<Occasion>

    /// Current global popularity (0...1) — a small quality/well-known signal.
    let popularity: Double
    /// How many people had "been" here when it first appeared (for early-discovery credit).
    let historicalCheckins: Int
    /// Whether it has since become a trending/notable spot.
    let isTrending: Bool

    /// Curated landmark / "essentials" status.
    let isLandmark: Bool
    /// Mock Michelin recognition — clearly prototype data.
    let michelinStars: Int          // 0 = none

    let dishes: [Dish]
    let blurb: String

    /// Present only for listings retrieved from Apple Maps. Unknown attributes stay unknown.
    var listing: RestaurantListing? = nil

    // Derived helpers -------------------------------------------------------

    /// Prices formatted for the restaurant's home city currency (resolved by the store).
    func priceString(currency: String) -> String { price.display(currency: currency) }

    var isMichelin: Bool { michelinStars > 0 }
}

struct RestaurantListing: Codable, Hashable {
    var providerID: String?
    var address: String
    var phone: String?
    var website: URL?
    var mapsURL: URL?
    var fetchedAt: Date
}
