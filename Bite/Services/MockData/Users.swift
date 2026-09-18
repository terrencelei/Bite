import Foundation

/// The people of the prototype. Preference vectors are hand-tuned so taste-match values
/// land in believable, varied ranges relative to the current user (Terrence).
enum Users {

    // Terser vector construction.
    private static func v(_ pairs: [TasteDimension: Double]) -> TasteVector { TasteVector(pairs) }

    /// The seeded current user.
    static let terrence = User(
        id: "u-terrence", name: "Terrence", handle: "@terrence", avatarEmoji: "🧑🏻‍🍳",
        preferences: v([
            .japanese: 0.92, .sichuan: 0.88, .chinese: 0.85, .korean: 0.80, .shanghainese: 0.6,
            .cantonese: 0.55, .novelty: 0.85, .atmosphere: 0.78, .value: 0.72, .authenticity: 0.8,
            .spicy: 0.82, .coffee: 0.7, .casual: 0.6, .streetFood: 0.65, .fineDining: 0.6,
            .dessert: 0.4, .italian: 0.45, .french: 0.35, .mexican: 0.4
        ]),
        cityIDs: ["shanghai", "seoul", "tokyo", "sf", "nyc"],
        tasteTraits: ["Adventurous", "Value-conscious", "Atmosphere matters", "Loves Asian cuisines"],
        restaurantsVisited: 142, citiesCount: 8, countriesCount: 4, isCurrentUser: true
    )

    // MARK: Friends

    static let jason = User(
        id: "u-jason", name: "Jason", handle: "@jasoneats", avatarEmoji: "👨🏻‍💼",
        preferences: v([
            .japanese: 0.9, .sichuan: 0.9, .chinese: 0.86, .korean: 0.82, .shanghainese: 0.62,
            .cantonese: 0.6, .novelty: 0.86, .atmosphere: 0.74, .value: 0.7, .authenticity: 0.82,
            .spicy: 0.86, .coffee: 0.66, .casual: 0.58, .streetFood: 0.66, .fineDining: 0.64,
            .dessert: 0.42, .italian: 0.44, .french: 0.4, .mexican: 0.42
        ]),
        cityIDs: ["seoul", "shanghai", "tokyo"],
        tasteTraits: ["Spice seeker", "Sushi obsessive", "Early to new spots"],
        restaurantsVisited: 126, citiesCount: 6, countriesCount: 3
    )

    static let emily = User(
        id: "u-emily", name: "Emily", handle: "@emilytastes", avatarEmoji: "👩🏻",
        preferences: v([
            .japanese: 0.82, .sichuan: 0.7, .chinese: 0.8, .korean: 0.7, .shanghainese: 0.7,
            .cantonese: 0.6, .novelty: 0.8, .atmosphere: 0.88, .value: 0.6, .authenticity: 0.72,
            .spicy: 0.6, .coffee: 0.85, .casual: 0.55, .streetFood: 0.5, .fineDining: 0.75,
            .dessert: 0.7, .italian: 0.6, .french: 0.55, .mexican: 0.4
        ]),
        cityIDs: ["shanghai", "sf"],
        tasteTraits: ["Ambiance-first", "Café regular", "Sweet tooth"],
        restaurantsVisited: 98, citiesCount: 5, countriesCount: 3
    )

    static let kevin = User(
        id: "u-kevin", name: "Kevin", handle: "@kevscheap", avatarEmoji: "🧑🏻",
        preferences: v([
            .japanese: 0.7, .sichuan: 0.85, .chinese: 0.8, .korean: 0.78, .shanghainese: 0.5,
            .cantonese: 0.5, .novelty: 0.6, .atmosphere: 0.5, .value: 0.95, .authenticity: 0.8,
            .spicy: 0.9, .coffee: 0.55, .casual: 0.9, .streetFood: 0.92, .fineDining: 0.25,
            .dessert: 0.45, .italian: 0.4, .french: 0.2, .mexican: 0.7
        ]),
        cityIDs: ["shanghai", "seoul"],
        tasteTraits: ["Street-food devotee", "Value hawk", "Loves heat"],
        restaurantsVisited: 154, citiesCount: 4, countriesCount: 2
    )

    static let alex = User(
        id: "u-alex", name: "Alex", handle: "@alexdines", avatarEmoji: "🧑🏼",
        preferences: v([
            .japanese: 0.6, .sichuan: 0.4, .chinese: 0.5, .korean: 0.45, .shanghainese: 0.4,
            .cantonese: 0.4, .novelty: 0.7, .atmosphere: 0.85, .value: 0.4, .authenticity: 0.6,
            .spicy: 0.35, .coffee: 0.75, .casual: 0.5, .streetFood: 0.35, .fineDining: 0.9,
            .dessert: 0.7, .italian: 0.85, .french: 0.88, .mexican: 0.4
        ]),
        cityIDs: ["nyc", "sf"],
        tasteTraits: ["Fine-dining fan", "Loves Italian & French", "Wine-forward"],
        restaurantsVisited: 111, citiesCount: 7, countriesCount: 5
    )

    static let mina = User(
        id: "u-mina", name: "Mina", handle: "@minaseoul", avatarEmoji: "👩🏻‍🎨",
        preferences: v([
            .japanese: 0.75, .sichuan: 0.6, .chinese: 0.6, .korean: 0.95, .shanghainese: 0.4,
            .cantonese: 0.4, .novelty: 0.82, .atmosphere: 0.8, .value: 0.65, .authenticity: 0.85,
            .spicy: 0.78, .coffee: 0.9, .casual: 0.7, .streetFood: 0.75, .fineDining: 0.55,
            .dessert: 0.8, .italian: 0.45, .french: 0.4, .mexican: 0.5
        ]),
        cityIDs: ["seoul", "tokyo"],
        tasteTraits: ["Seoul native", "Coffee & dessert lover", "Korean-food guide"],
        restaurantsVisited: 173, citiesCount: 5, countriesCount: 4
    )

    static let diego = User(
        id: "u-diego", name: "Diego", handle: "@diegobites", avatarEmoji: "🧑🏽",
        preferences: v([
            .japanese: 0.65, .sichuan: 0.7, .chinese: 0.6, .korean: 0.6, .shanghainese: 0.35,
            .cantonese: 0.4, .novelty: 0.7, .atmosphere: 0.6, .value: 0.8, .authenticity: 0.75,
            .spicy: 0.85, .coffee: 0.7, .casual: 0.85, .streetFood: 0.9, .fineDining: 0.35,
            .dessert: 0.5, .italian: 0.6, .french: 0.35, .mexican: 0.95
        ]),
        cityIDs: ["sf", "nyc"],
        tasteTraits: ["Taco authority", "Street-food first", "Always finds value"],
        restaurantsVisited: 132, citiesCount: 6, countriesCount: 4
    )

    static let sophie = User(
        id: "u-sophie", name: "Sophie", handle: "@sophieeats", avatarEmoji: "👩🏼‍🦰",
        preferences: v([
            .japanese: 0.85, .sichuan: 0.65, .chinese: 0.72, .korean: 0.7, .shanghainese: 0.6,
            .cantonese: 0.55, .novelty: 0.9, .atmosphere: 0.82, .value: 0.55, .authenticity: 0.7,
            .spicy: 0.6, .coffee: 0.8, .casual: 0.5, .streetFood: 0.55, .fineDining: 0.82,
            .dessert: 0.75, .italian: 0.7, .french: 0.68, .mexican: 0.45
        ]),
        cityIDs: ["nyc", "tokyo", "shanghai"],
        tasteTraits: ["Novelty chaser", "Omakase regular", "Design-forward"],
        restaurantsVisited: 120, citiesCount: 8, countriesCount: 6
    )

    static let ryan = User(
        id: "u-ryan", name: "Ryan", handle: "@ryanhungry", avatarEmoji: "🧑🏾",
        preferences: v([
            .japanese: 0.78, .sichuan: 0.8, .chinese: 0.78, .korean: 0.76, .shanghainese: 0.55,
            .cantonese: 0.5, .novelty: 0.72, .atmosphere: 0.65, .value: 0.78, .authenticity: 0.78,
            .spicy: 0.8, .coffee: 0.72, .casual: 0.75, .streetFood: 0.7, .fineDining: 0.5,
            .dessert: 0.5, .italian: 0.55, .french: 0.4, .mexican: 0.55
        ]),
        cityIDs: ["sf", "shanghai"],
        tasteTraits: ["Balanced eater", "Ramen hunter", "Weekend explorer"],
        restaurantsVisited: 108, citiesCount: 5, countriesCount: 3
    )

    /// All friends (people other than the current user).
    static let friends: [User] = [jason, emily, kevin, alex, mina, diego, sophie, ryan]

    /// Everyone, current user first.
    static let all: [User] = [terrence] + friends

    static func by(id: String) -> User? { all.first { $0.id == id } }
}
