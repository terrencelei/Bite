import SwiftUI

// MARK: - Taste dimensions

/// The axes of the shared "taste space". Both restaurants (as attribute vectors) and
/// users (as preference vectors) are embedded here, which makes match %, taste-match,
/// and group recommendations all reduce to vector math over the same basis.
enum TasteDimension: String, CaseIterable, Codable, Hashable {
    // Cuisine affinities
    case chinese, sichuan, cantonese, shanghainese, japanese, korean, italian, french, mexican
    // Style / experience
    case fineDining, casual, streetFood
    // Values
    case value, atmosphere, novelty, authenticity
    // Flavor
    case spicy, dessert, coffee

    var label: String {
        switch self {
        case .chinese: return "Chinese"
        case .sichuan: return "Sichuan"
        case .cantonese: return "Cantonese"
        case .shanghainese: return "Shanghainese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .italian: return "Italian"
        case .french: return "French"
        case .mexican: return "Mexican"
        case .fineDining: return "Fine Dining"
        case .casual: return "Casual"
        case .streetFood: return "Street Food"
        case .value: return "Value"
        case .atmosphere: return "Atmosphere"
        case .novelty: return "Novelty"
        case .authenticity: return "Authenticity"
        case .spicy: return "Spicy"
        case .dessert: return "Dessert"
        case .coffee: return "Coffee"
        }
    }
}

// MARK: - Cuisine

/// A restaurant's headline cuisine. Each maps to an SF Symbol + color and to the taste
/// dimensions it activates, so mock data stays terse while vectors stay rich.
enum Cuisine: String, CaseIterable, Codable, Hashable, Identifiable {
    case restaurant
    case modernChinese, sichuan, cantonese, shanghainese, hotpot, yunnan
    case sushi, ramen, izakaya, japanese
    case korean, koreanBBQ
    case italian, french, californian, american, mexican, thai, vietnamese
    case cafe, dessert, bakery

    var id: String { rawValue }

    var label: String {
        switch self {
        case .restaurant: return "Restaurant"
        case .modernChinese: return "Modern Chinese"
        case .sichuan: return "Sichuan"
        case .cantonese: return "Cantonese"
        case .shanghainese: return "Shanghainese"
        case .hotpot: return "Hot Pot"
        case .yunnan: return "Yunnan"
        case .sushi: return "Sushi"
        case .ramen: return "Ramen"
        case .izakaya: return "Izakaya"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .koreanBBQ: return "Korean BBQ"
        case .italian: return "Italian"
        case .french: return "French"
        case .californian: return "Californian"
        case .american: return "American"
        case .mexican: return "Mexican"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .cafe: return "Café"
        case .dessert: return "Dessert"
        case .bakery: return "Bakery"
        }
    }

    /// SF Symbol used across cards and procedural imagery.
    var symbol: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .modernChinese, .shanghainese, .cantonese, .yunnan: return "takeoutbag.and.cup.and.straw.fill"
        case .sichuan, .hotpot: return "flame.fill"
        case .sushi: return "fish.fill"
        case .ramen: return "bowl.fill"
        case .izakaya, .japanese: return "wineglass.fill"
        case .korean, .koreanBBQ: return "flame.fill"
        case .italian: return "fork.knife"
        case .french: return "wineglass.fill"
        case .californian, .american: return "fork.knife"
        case .mexican: return "leaf.fill"
        case .thai, .vietnamese: return "leaf.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .bakery: return "birthday.cake.fill"
        }
    }

    /// The taste dimensions this cuisine primarily activates (weight 0...1).
    var dimensionWeights: [TasteDimension: Double] {
        switch self {
        case .restaurant: return [:]
        case .modernChinese: return [.chinese: 1, .novelty: 0.6, .atmosphere: 0.6]
        case .sichuan: return [.chinese: 0.7, .sichuan: 1, .spicy: 0.9, .authenticity: 0.6]
        case .cantonese: return [.chinese: 0.8, .cantonese: 1, .authenticity: 0.6]
        case .shanghainese: return [.chinese: 0.8, .shanghainese: 1, .authenticity: 0.6]
        case .hotpot: return [.chinese: 0.6, .sichuan: 0.5, .spicy: 0.8, .casual: 0.7]
        case .yunnan: return [.chinese: 0.7, .authenticity: 0.7, .novelty: 0.6]
        case .sushi: return [.japanese: 1, .fineDining: 0.6, .authenticity: 0.7]
        case .ramen: return [.japanese: 0.9, .casual: 0.8, .streetFood: 0.5]
        case .izakaya: return [.japanese: 0.9, .casual: 0.7, .atmosphere: 0.7]
        case .japanese: return [.japanese: 1, .authenticity: 0.6]
        case .korean: return [.korean: 1, .spicy: 0.6, .casual: 0.6]
        case .koreanBBQ: return [.korean: 1, .casual: 0.7, .atmosphere: 0.6]
        case .italian: return [.italian: 1, .atmosphere: 0.6]
        case .french: return [.french: 1, .fineDining: 0.8, .atmosphere: 0.7]
        case .californian: return [.novelty: 0.7, .atmosphere: 0.6, .fineDining: 0.5]
        case .american: return [.casual: 0.7, .value: 0.5]
        case .mexican: return [.mexican: 1, .spicy: 0.6, .streetFood: 0.6, .value: 0.5]
        case .thai: return [.spicy: 0.7, .streetFood: 0.6, .authenticity: 0.6]
        case .vietnamese: return [.streetFood: 0.6, .authenticity: 0.6, .value: 0.6]
        case .cafe: return [.coffee: 1, .casual: 0.7, .atmosphere: 0.6]
        case .dessert: return [.dessert: 1, .casual: 0.6]
        case .bakery: return [.dessert: 0.8, .coffee: 0.5, .casual: 0.6]
        }
    }

    /// Cuisine "family" used for cuisine-depth achievements (e.g. all ramen counts as ramen).
    var family: String {
        switch self {
        case .restaurant: return "Unknown"
        case .modernChinese, .shanghainese, .cantonese, .yunnan: return "Chinese"
        case .sichuan: return "Sichuan"
        case .hotpot: return "Hot Pot"
        case .sushi: return "Sushi"
        case .ramen: return "Ramen"
        case .izakaya, .japanese: return "Japanese"
        case .korean, .koreanBBQ: return "Korean"
        case .italian: return "Italian"
        case .french: return "French"
        case .californian, .american: return "American"
        case .mexican: return "Mexican"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .cafe: return "Café"
        case .dessert, .bakery: return "Dessert"
        }
    }
}

// MARK: - Price

enum PriceLevel: Int, Codable, CaseIterable, Comparable, Hashable {
    case unknown = 0
    case budget = 1, moderate = 2, upscale = 3, luxury = 4

    static func < (lhs: PriceLevel, rhs: PriceLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Currency-aware glyphs, e.g. "¥¥¥" or "$$$".
    func display(currency: String) -> String {
        self == .unknown ? "Price unavailable" : String(repeating: currency, count: rawValue)
    }
}

// MARK: - Occasion / dining context

enum Occasion: String, CaseIterable, Codable, Hashable, Identifiable {
    case dateNight, friends, quickBite, cheapEats, explore, lateNight, coffee, dessert, solo, celebration, business

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateNight: return "Date Night"
        case .friends: return "Friends"
        case .quickBite: return "Quick Bite"
        case .cheapEats: return "Cheap Eats"
        case .explore: return "Explore"
        case .lateNight: return "Late Night"
        case .coffee: return "Coffee"
        case .dessert: return "Dessert"
        case .solo: return "Solo"
        case .celebration: return "Celebration"
        case .business: return "Business"
        }
    }

    var symbol: String {
        switch self {
        case .dateNight: return "heart.fill"
        case .friends: return "person.2.fill"
        case .quickBite: return "bolt.fill"
        case .cheapEats: return "dollarsign.circle.fill"
        case .explore: return "safari.fill"
        case .lateNight: return "moon.stars.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .solo: return "person.fill"
        case .celebration: return "sparkles"
        case .business: return "briefcase.fill"
        }
    }

    /// Chips surfaced on Discover's "What are you feeling?" row.
    static let discoverChips: [Occasion] = [.dateNight, .friends, .quickBite, .cheapEats, .explore, .lateNight, .coffee, .dessert]
}
