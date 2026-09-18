import Foundation

/// Static city catalog for the prototype world.
enum Cities {
    static let shanghai = City(
        id: "shanghai", name: "Shanghai", country: "China", countryFlag: "🇨🇳",
        currency: "¥", center: Coordinate(latitude: 31.2304, longitude: 121.4737),
        neighborhoods: ["Jing'an", "Xuhui", "Huangpu", "Changning", "Pudong",
                        "Hongkou", "Xintiandi", "French Concession", "Yangpu", "Minhang"]
    )
    static let seoul = City(
        id: "seoul", name: "Seoul", country: "South Korea", countryFlag: "🇰🇷",
        currency: "₩", center: Coordinate(latitude: 37.5665, longitude: 126.9780),
        neighborhoods: ["Seongsu", "Gangnam", "Itaewon", "Hongdae", "Jongno", "Mapo", "Yeonnam"]
    )
    static let sf = City(
        id: "sf", name: "San Francisco", country: "United States", countryFlag: "🇺🇸",
        currency: "$", center: Coordinate(latitude: 37.7749, longitude: -122.4194),
        neighborhoods: ["Mission", "Hayes Valley", "SoMa", "North Beach", "Richmond", "Marina", "Nob Hill"]
    )
    static let nyc = City(
        id: "nyc", name: "New York", country: "United States", countryFlag: "🇺🇸",
        currency: "$", center: Coordinate(latitude: 40.7128, longitude: -74.0060),
        neighborhoods: ["East Village", "West Village", "Williamsburg", "Midtown", "Chinatown", "LES", "Flatiron"]
    )
    static let tokyo = City(
        id: "tokyo", name: "Tokyo", country: "Japan", countryFlag: "🇯🇵",
        currency: "¥", center: Coordinate(latitude: 35.6762, longitude: 139.6503),
        neighborhoods: ["Shibuya", "Shinjuku", "Ginza", "Nakameguro", "Ebisu"]
    )

    static let all: [City] = [shanghai, seoul, sf, nyc, tokyo]

    static func by(id: String) -> City? { all.first { $0.id == id } }
}
