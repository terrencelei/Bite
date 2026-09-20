import XCTest
import MapKit
@testable import BiteCore

final class MemoryPersistence: PersistenceService {
    var state: PersistedState?
    var failsLoad = false
    var failsSave = false
    var saves = 0
    func load() throws -> PersistedState? {
        if failsLoad { throw CocoaError(.fileReadCorruptFile) }
        return state
    }
    func save(_ state: PersistedState) throws {
        if failsSave { throw CocoaError(.fileWriteOutOfSpace) }
        // Exercise Codable, not just an in-memory reference copy.
        self.state = try JSONDecoder().decode(PersistedState.self, from: JSONEncoder().encode(state))
        saves += 1
    }
    func reset() { state = nil }
}

final class BiteCoreTests: XCTestCase {
    @MainActor func testLiveStartupContainsNoExampleData() async {
        let model = AppModel(persistence: MemoryPersistence())
        XCTAssertTrue(model.restaurants.isEmpty)
        XCTAssertTrue(model.rankings.isEmpty)
        XCTAssertTrue(model.friends.isEmpty)
        XCTAssertTrue(model.feed.isEmpty)
        XCTAssertFalse(model.onboardingComplete)
        XCTAssertEqual(model.currentUser.id, "local-user")
    }

    @MainActor func testRerankNeverComparesRestaurantWithItself() async {
        let model = AppModel(persistence: MemoryPersistence(), demoMode: true)
        for entry in model.rankings {
            let session = model.makeRankingSession(for: entry.restaurantID)
            XCTAssertFalse(session.sorted.contains { $0.restaurantID == entry.restaurantID })
        }
    }

    @MainActor func testLikesAndRankingPostsSurviveReload() async {
        let persistence = MemoryPersistence()
        let model = AppModel(persistence: persistence, demoMode: true)
        model.toggleLike("f1")
        let session = model.makeRankingSession(for: "sh-linglong")
        while !session.isFinished { session.choose(preferredNew: true) }
        model.applyRanking(session: session, tags: [])
        let restored = AppModel(persistence: persistence, demoMode: true)
        XCTAssertEqual(restored.feed, model.feed)
        XCTAssertEqual(restored.rankings, model.rankings)
        XCTAssertTrue(restored.feed.first { $0.id == "f1" }!.likedByCurrentUser)
        restored.toggleLike("f1")
        XCTAssertEqual(restored.feed.first { $0.id == "f1" }!.likeCount, 12)
    }

    @MainActor func testGroupUsesLearnedCurrentUserPreferences() async {
        let model = AppModel(persistence: MemoryPersistence(), demoMode: true)
        model.currentUser.preferences = TasteVector([.japanese: 1])
        let request = GroupRequest(memberIDs: [model.currentUser.id], cityID: "shanghai", maxPrice: .luxury, occasion: nil, cuisineFamily: nil)
        let actual = model.groupRecommendations(request: request)
        let expected = model.groupEngine.recommend(members: [model.currentUser], candidates: model.restaurants, request: request)
        XCTAssertEqual(actual, expected)
    }

    @MainActor func testBudgetIsAHardConstraint() async {
        let model = AppModel(persistence: MemoryPersistence(), demoMode: true)
        var context = RecommendationContext.empty
        context.maxPrice = .budget
        let results = model.recommendations(context: context, excludeVisited: false)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { model.restaurant($0.restaurantID)!.price == .budget })
    }

    @MainActor func testSavedLiveListingSurvivesRelaunchWithoutInventedMetadata() async throws {
        let persistence = MemoryPersistence()
        let model = AppModel(persistence: persistence)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41)))
        item.name = "Test Restaurant"
        let (restaurant, city) = try XCTUnwrap(AppleRestaurantSearch.map(item))
        XCTAssertEqual(restaurant.price, .unknown)
        XCTAssertEqual(restaurant.cuisine, .restaurant)
        XCTAssertEqual(restaurant.michelinStars, 0)
        XCTAssertEqual(restaurant.id, AppleRestaurantSearch.map(item)?.0.id)
        model.mergeListings([restaurant], cities: [city])
        model.toggleWantToTry(restaurant.id)
        let restored = AppModel(persistence: persistence)
        XCTAssertEqual(restored.restaurant(restaurant.id), restaurant)
        XCTAssertTrue(restored.isWantToTry(restaurant.id))
        XCTAssertNil(restored.recommendation(for: restaurant.id))
        let session = restored.makeRankingSession(for: restaurant.id)
        XCTAssertTrue(session.isFinished)
        restored.applyRanking(session: session, tags: [.value])
        let again = AppModel(persistence: persistence)
        XCTAssertTrue(again.isBeen(restaurant.id))
        XCTAssertFalse(again.isWantToTry(restaurant.id))
        XCTAssertEqual(again.buildAchievementStats().cuisineFamilies.count, 0)
    }

    @MainActor func testReadFailureCannotOverwriteExistingData() async {
        let persistence = MemoryPersistence()
        persistence.failsLoad = true
        let model = AppModel(persistence: persistence)
        model.persist()
        XCTAssertNotNil(model.storageError)
        XCTAssertEqual(persistence.saves, 0)
    }

    @MainActor func testSaveFailureIsVisibleAndRetryWorks() async {
        let persistence = MemoryPersistence()
        let model = AppModel(persistence: persistence)
        persistence.failsSave = true
        model.persist()
        XCTAssertNotNil(model.storageError)
        persistence.failsSave = false
        model.persist()
        XCTAssertNil(model.storageError)
    }

    @MainActor func testRegionFilterHandlesDateLineAndOutsideResults() async {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 179.9),
                                        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        XCTAssertTrue(AppleRestaurantSearch.contains(CLLocationCoordinate2D(latitude: 0, longitude: -179.9), in: region))
        XCTAssertFalse(AppleRestaurantSearch.contains(CLLocationCoordinate2D(latitude: 0, longitude: -170), in: region))
        XCTAssertFalse(AppleRestaurantSearch.contains(CLLocationCoordinate2D(latitude: 2, longitude: 179.9), in: region))
    }
}

@MainActor final class ControlledSearch: RestaurantSearching {
    var requests: [CheckedContinuation<RestaurantSearchResult, Error>] = []
    func search(in region: MKCoordinateRegion, query: String) async throws -> RestaurantSearchResult {
        try await withCheckedThrowingContinuation { requests.append($0) }
    }
    func findArea(_ query: String) async throws -> (MKCoordinateRegion, String) {
        (MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41),
                            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)), query)
    }
    func cancel() { /* Deliberately complete stale requests to exercise the generation guard. */ }
}

extension BiteCoreTests {
    @MainActor func testSupersededSearchCannotReplaceLatestResults() async throws {
        let service = ControlledSearch()
        let store = NearbySearchStore(service: service)
        let model = AppModel(persistence: MemoryPersistence())
        store.findArea("First", model: model)
        for _ in 0..<100 where service.requests.count < 1 { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertEqual(service.requests.count, 1)
        store.findArea("Second", model: model)
        for _ in 0..<100 where service.requests.count < 2 { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertEqual(service.requests.count, 2)
        guard service.requests.count == 2 else { return }
        service.requests[1].resume(returning: RestaurantSearchResult(restaurants: [], cities: []))
        for _ in 0..<100 where store.isLoading { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertTrue(store.didSearch)
        service.requests[0].resume(throwing: URLError(.notConnectedToInternet))
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(store.areaName, "Second")
        XCTAssertNil(store.errorMessage)
        XCTAssertFalse(store.isLoading)
    }

    @MainActor func testSearchFailureCanBeRetried() async throws {
        let service = ControlledSearch()
        let store = NearbySearchStore(service: service)
        let model = AppModel(persistence: MemoryPersistence())
        store.findArea("Test city", model: model)
        for _ in 0..<100 where service.requests.isEmpty { try await Task.sleep(for: .milliseconds(5)) }
        guard let first = service.requests.first else { XCTFail("Missing request"); return }
        first.resume(throwing: URLError(.notConnectedToInternet))
        for _ in 0..<100 where store.isLoading { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertNotNil(store.errorMessage)
        store.search(model: model)
        for _ in 0..<100 where service.requests.count < 2 { try await Task.sleep(for: .milliseconds(5)) }
        guard service.requests.count == 2 else { XCTFail("Missing retry"); return }
        service.requests[1].resume(returning: RestaurantSearchResult(restaurants: [], cities: []))
        for _ in 0..<100 where store.isLoading { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertNil(store.errorMessage)
        XCTAssertTrue(store.didSearch)
    }

    func testFilePersistenceRoundTripResetAndCorruptData() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = FilePersistenceService(directory: directory)
        XCTAssertNil(try service.load())
        var state = PersistedState()
        state.onboardingComplete = true
        try service.save(state)
        XCTAssertTrue(try XCTUnwrap(service.load()).onboardingComplete)
        try Data("broken json".utf8).write(to: directory.appendingPathComponent("bite_live_state.json"))
        XCTAssertThrowsError(try service.load())
        try service.reset()
        XCTAssertNil(try service.load())
    }
}

extension BiteCoreTests {
    func testRankingSessionResolvesEveryPositionInLargeLists() {
        let entries = (0..<100).map { i in
            RankingEntry(id: "rank-\(i)", restaurantID: "r-\(i)", score: 100 - Double(i), comparisons: 0, dateRanked: Date())
        }
        for insertion in 0...entries.count {
            let session = RankingSession(newRestaurantID: "new", scopeName: "Test", existing: entries)
            while let opponent = session.currentOpponentID {
                let opponentIndex = entries.firstIndex { $0.restaurantID == opponent }!
                session.choose(preferredNew: insertion <= opponentIndex)
            }
            XCTAssertTrue(session.isFinished)
            XCTAssertEqual(session.resultIndex, insertion)
        }
    }
}
