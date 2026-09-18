import Foundation

/// Curated landmark collections — the "essentials" a local should know.
enum Collections {
    static let all: [RestaurantCollection] = [
        RestaurantCollection(
            id: "shanghai-essentials", title: "Shanghai Essentials",
            subtitle: "5 restaurants that define the city", symbol: "star.square.fill",
            restaurantIDs: ["sh-fuhehui", "sh-dintaifung", "sh-laozhengxing", "sh-haidilao", "sh-hakkasan"]),
        RestaurantCollection(
            id: "seoul-essentials", title: "Seoul Essentials",
            subtitle: "The city's must-eat table", symbol: "star.square.fill",
            restaurantIDs: ["se-mingles", "se-gwangjang", "se-jungsik", "se-parkhae", "se-onjium"]),
        RestaurantCollection(
            id: "nyc-classics", title: "NYC Classics",
            subtitle: "New York institutions", symbol: "star.square.fill",
            restaurantIDs: ["ny-lucali", "ny-veselka", "ny-xianfamous", "ny-atomix", "ny-rezdora"]),
        RestaurantCollection(
            id: "michelin-explorer", title: "Michelin Explorer",
            subtitle: "Recognized in the mock guide", symbol: "star.circle.fill",
            restaurantIDs: Restaurants.all.filter { $0.isMichelin }.map(\.id)),
    ]

    static func by(id: String) -> RestaurantCollection? { all.first { $0.id == id } }
}
