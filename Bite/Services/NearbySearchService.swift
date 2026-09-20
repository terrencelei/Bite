import Foundation
import MapKit
import Observation

struct RestaurantSearchResult {
    var restaurants: [Restaurant]
    var cities: [City]
}

@MainActor
protocol RestaurantSearching {
    func search(in region: MKCoordinateRegion, query: String) async throws -> RestaurantSearchResult
    func findArea(_ query: String) async throws -> (MKCoordinateRegion, String)
    func cancel()
}

/// Apple's live place directory; no API key or bundled restaurant catalog.
@MainActor
final class AppleRestaurantSearch: RestaurantSearching {
    private var activeSearch: MKLocalSearch?

    func cancel() { activeSearch?.cancel(); activeSearch = nil }

    private func run(_ request: MKLocalSearch.Request) async throws -> MKLocalSearch.Response {
        let search = MKLocalSearch(request: request)
        activeSearch = search
        defer { if activeSearch === search { activeSearch = nil } }
        return try await search.start()
    }

    func search(in region: MKCoordinateRegion, query: String) async throws -> RestaurantSearchResult {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.isEmpty ? "Restaurants" : query
        request.region = region
        request.regionPriority = .required
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery])
        let response: MKLocalSearch.Response
        do { response = try await run(request) }
        catch let error as MKError where error.code == .placemarkNotFound {
            return RestaurantSearchResult(restaurants: [], cities: [])
        }
        var restaurants: [String: Restaurant] = [:]
        var cities: [String: City] = [:]
        for item in response.mapItems where Self.contains(item.placemark.coordinate, in: region) {
            guard let mapped = Self.map(item) else { continue }
            restaurants[mapped.0.id] = mapped.0
            cities[mapped.1.id] = mapped.1
        }
        let center = Coordinate(latitude: region.center.latitude, longitude: region.center.longitude)
        return RestaurantSearchResult(
            restaurants: restaurants.values.sorted { $0.coordinate.distance(to: center) < $1.coordinate.distance(to: center) },
            cities: Array(cities.values))
    }

    func findArea(_ query: String) async throws -> (MKCoordinateRegion, String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        let response = try await run(request)
        guard let item = response.mapItems.first else { throw MKError(.placemarkNotFound) }
        return (MKCoordinateRegion(center: item.placemark.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000),
                item.name ?? query)
    }

    static func contains(_ coordinate: CLLocationCoordinate2D, in region: MKCoordinateRegion) -> Bool {
        let longitudeDistance = abs((coordinate.longitude - region.center.longitude + 540).truncatingRemainder(dividingBy: 360) - 180)
        return abs(coordinate.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
            && longitudeDistance <= region.span.longitudeDelta / 2
    }

    static func map(_ item: MKMapItem) -> (Restaurant, City)? {
        guard let name = item.name, !name.isEmpty else { return nil }
        let p = item.placemark
        guard CLLocationCoordinate2DIsValid(p.coordinate) else { return nil }
        let countryCode = p.isoCountryCode ?? ""
        let cityName = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? "Area"
        let cityID = ["place", countryCode, p.administrativeArea ?? "", cityName].joined(separator: "|")
        let coordinate = Coordinate(latitude: p.coordinate.latitude, longitude: p.coordinate.longitude)
        let providerID = item.identifier?.rawValue
        // Provider identity is preferred; fallback is reproducible across launches.
        let fallback = "\(name.lowercased())|\(String(format: "%.5f", coordinate.latitude))|\(String(format: "%.5f", coordinate.longitude))"
        let id = "apple|" + (providerID ?? fallback)
        let cuisine: Cuisine = item.pointOfInterestCategory == .cafe ? .cafe : item.pointOfInterestCategory == .bakery ? .bakery : .restaurant
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [URLQueryItem(name: "q", value: name),
                                 URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)")]
        if let providerID { components.queryItems?.append(URLQueryItem(name: "place-id", value: providerID)) }
        let address = [p.subThoroughfare, p.thoroughfare, p.locality, p.administrativeArea, p.postalCode]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        let restaurant = Restaurant(id: id, name: name, cuisine: cuisine,
            subCuisine: "Apple Maps", cityID: cityID, neighborhood: p.subLocality ?? cityName,
            price: .unknown, coordinate: coordinate, attributes: TasteVector(), occasions: [],
            popularity: 0, historicalCheckins: 0, isTrending: false, isLandmark: false, michelinStars: 0,
            dishes: [], blurb: "", listing: RestaurantListing(providerID: providerID, address: address,
                phone: item.phoneNumber, website: safeWebsite(item.url), mapsURL: components.url, fetchedAt: Date()))
        let flag = countryCode.count == 2 ? String(String.UnicodeScalarView(countryCode.uppercased().unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) })) : "🌐"
        let city = City(id: cityID, name: cityName, country: p.country ?? "Unknown country", countryFlag: flag,
                        currency: "", center: coordinate, neighborhoods: [])
        return (restaurant, city)
    }

    private static func safeWebsite(_ url: URL?) -> URL? {
        guard let url, ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
}

/// Shared by Discover and Map. Requests are explicit, cancellable, and last-request-wins.
@MainActor @Observable
final class NearbySearchStore {
    var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                                    span: MKCoordinateSpan(latitudeDelta: 45, longitudeDelta: 60))
    private(set) var regionRevision = 0
    private(set) var hasArea = false
    private(set) var areaName = "Choose an area"
    private(set) var results: [Restaurant] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var didSearch = false
    var query = ""
    let location = LocationService()
    @ObservationIgnored private let service: RestaurantSearching
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var generation = 0

    init(service: RestaurantSearching? = nil) { self.service = service ?? AppleRestaurantSearch() }

    func useMyLocation(model: AppModel) {
        task?.cancel(); service.cancel(); generation += 1
        isLoading = false; errorMessage = nil
        location.onLocation = { [weak self, weak model] coordinate in
            guard let self, let model else { return }
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 4000, longitudinalMeters: 4000)
            self.setArea(region, name: "Near you")
            self.search(in: region, model: model)
        }
        location.request()
    }

    func findArea(_ name: String, model: AppModel) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        location.cancel()
        begin()
        let token = generation
        task = Task {
            do {
                let (region, label) = try await service.findArea(name)
                guard !Task.isCancelled, token == generation else { return }
                setArea(region, name: label)
                await fetch(region, model: model, token: token)
            } catch { finish(error: error, token: token) }
        }
    }

    func search(in region: MKCoordinateRegion? = nil, model: AppModel) {
        guard hasArea || region != nil else { return }
        location.cancel()
        let target = region ?? self.region
        // Very broad queries make poor local results and can omit most of a city.
        guard target.span.latitudeDelta <= 0.5, target.span.longitudeDelta <= 0.5 else {
            errorMessage = "Zoom in to a neighborhood or search for a city to find restaurants."; return
        }
        self.region = target
        hasArea = true
        begin()
        let token = generation
        task = Task { await fetch(target, model: model, token: token) }
    }

    func clear() {
        task?.cancel(); service.cancel(); location.cancel(); generation += 1
        results = []; isLoading = false; errorMessage = nil; didSearch = false
        hasArea = false; areaName = "Choose an area"; query = ""
        region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                                    span: MKCoordinateSpan(latitudeDelta: 45, longitudeDelta: 60))
        regionRevision += 1
    }

    private func setArea(_ region: MKCoordinateRegion, name: String) {
        self.region = region; areaName = name; hasArea = true; regionRevision += 1
    }

    private func begin() {
        task?.cancel(); service.cancel(); generation += 1
        isLoading = true; errorMessage = nil; results = []; didSearch = false
    }

    private func fetch(_ region: MKCoordinateRegion, model: AppModel, token: Int) async {
        do {
            let response = try await service.search(in: region, query: query.trimmingCharacters(in: .whitespacesAndNewlines))
            guard !Task.isCancelled, token == generation else { return }
            model.mergeListings(response.restaurants, cities: response.cities)
            results = response.restaurants
            isLoading = false; didSearch = true
        } catch { finish(error: error, token: token) }
    }

    private func finish(error: Error, token: Int) {
        guard token == generation, !Task.isCancelled else { return }
        isLoading = false
        errorMessage = "Couldn’t load this area. Check your connection, then try again or search a nearby city."
    }
}
