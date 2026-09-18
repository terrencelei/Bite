import Foundation
import CoreLocation

/// A primary city in the prototype's world.
struct City: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let country: String
    let countryFlag: String
    let currency: String          // "¥", "$", "₩"
    let center: Coordinate
    /// Neighborhoods that exist in this city (used for completion + exploration achievements).
    let neighborhoods: [String]

    var isAsian: Bool {
        ["China", "South Korea", "Japan"].contains(country)
    }
}

/// A Codable-friendly coordinate (CLLocationCoordinate2D isn't Codable by default).
struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Rough great-circle distance in kilometers.
    func distance(to other: Coordinate) -> Double {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b) / 1000.0
    }
}
