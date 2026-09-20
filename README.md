# Bite

[Website](https://terrencelei.github.io/Bite/) · [中文介绍](https://terrencelei.github.io/Bite/zh/) · [Privacy](PRIVACY.md)

Bite is an iOS restaurant discovery app built with SwiftUI, MapKit, and Core Location. The normal app uses **live Apple Maps listings**, starts with an empty personal history, and stores saved restaurants and rankings on the device.

## Run

1. Open `Bite.xcodeproj` in Xcode 16 or newer.
2. Choose the `Bite` scheme and an iOS 18+ device or simulator.
3. Run, finish the short welcome screen, and tap **Near me** or enter a city, neighborhood, or address.

No API keys or third-party packages are required. Live search and map tiles need a network connection. In Simulator, set a simulated location (Features → Location) before using Near me. On a physical device, choose your own signing team.

## What works

- **Discover:** search an area and optionally narrow by restaurant name or cuisine. Results come from Apple Maps, not the old example catalog.
- **Map:** show your location, pan and zoom anywhere, and tap **Search this area**. Switch between restaurant search results, saved places, and places you have ranked. Native restaurant POIs on the map can also be opened and saved, even if they were not returned in the latest search.
- **Restaurant detail:** real name, address, available phone/website information, and an Apple Maps link. Save a restaurant or start the pairwise ranking flow.
- **Saved and Rankings:** retained place details survive relaunch and remain available offline. Ranking removes a restaurant from Want to Try. Re-ranking excludes self-comparisons.
- **Profile and Food Passport:** statistics come from your own rankings. Deleting local data requires an explicit confirmation in the app.
- Location permission is requested only when you tap Near me. Denied permission, unavailable GPS, empty searches, and failed network requests have recovery guidance. You can search manually without location access.

### Search coverage and metadata

Apple Maps search is a ranked search service, **not an exhaustive export of every restaurant in a region**. Bite shows the results returned inside the requested map region without imposing an additional display limit. Search by name/cuisine or move to a smaller area to find more places. Very broad map searches ask you to zoom in. Coverage and place accuracy depend on Apple Maps.

The API does not provide verified menu prices, cuisine-specific taste vectors, restaurant photos, Michelin ratings, or social activity. Bite does not invent those fields: price is shown as unavailable, generic restaurants remain uncategorized, and live listings have no fabricated match percentages or suggested dishes. Illustrations are placeholders, not restaurant photographs. The demo-only social/recommendation screens and seed data remain in source for regression tests; the normal app does not expose the seeded social network.

## Persistence and the previous prototype

Live user data is in `Documents/bite_live_state.json`. The old prototype's `bite_state.json` is left untouched and is not imported, because it contains fictional rankings and friends. The user starts fresh when moving from that prototype to this version.

Only saved/visited/ranked restaurant details are retained on disk; transient search results are bounded in memory. Writes are atomic and use file protection. Save failures appear in the app and can be retried. Unreadable data is preserved and blocks the normal interface instead of being silently replaced. No device location history is stored. See [PRIVACY.md](PRIVACY.md).

## Tests

Run the deterministic domain, persistence, and search-coordination tests on macOS 15+:

```sh
swift test
```

Build for an iOS simulator:

```sh
xcodebuild -project Bite.xcodeproj -scheme Bite \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The `BiteUITests` target exercises live search, saving/relaunch, and location permission flows. These integration tests need network access, an English-language simulator, and a simulated location, for example:

```sh
xcrun simctl location booted set 37.7749,-122.4194
xcodebuild -project Bite.xcodeproj -scheme Bite \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO test
```

## Release scope

This is a stronger local-first foundation, not a complete social-service launch. Accounts, cloud backup/sync, real friendships and shared feeds, richer licensed place metadata/photos, and App Store submission remain separate work. Device testing and release privacy disclosures must reflect the final distributed build. The English and Chinese website pages under `docs/` document the current app with real simulator screenshots. The app interface is currently English; the Chinese website does not imply app localization.

## Architecture

- `NearbySearchStore` coordinates explicit searches, cancels superseded work, and prevents stale results from replacing a newer area.
- `AppleRestaurantSearch` retrieves and maps Apple Maps listings, prefers provider place IDs, and filters results to the requested region.
- `LocationService` handles one-time location requests, denied permissions, and timeouts.
- `AppModel` owns the live catalog and personal state; `FilePersistenceService` writes protected, atomic JSON snapshots.
- Pure ranking and achievement engines are covered by the `BiteCore` Swift package tests. Seed fixtures are opt-in for regression tests.

## Website and deployment

GitHub Pages publishes the `docs/` directory from `main` at <https://terrencelei.github.io/Bite/>. Both language pages share `docs/assets/site.css`; current screenshots are under `docs/assets/live/`. Earlier prototype screenshots remain under `docs/assets/screens/` for history and are not used by the current website.

Preview the website locally:

```sh
python3 -m http.server 8000 --directory docs
# Open http://localhost:8000/ and http://localhost:8000/zh/
```

Pushes to `main` trigger GitHub Pages deployment. The separate `Build and core tests` workflow checks the app and core tests on pushes and pull requests. The live-network UI tests are run separately on a configured simulator.

## Verified changes

- Live area/name/cuisine search, nearby location access, and native map restaurant selection.
- Clean first-run profile; existing prototype data preserved separately.
- Fixed self-comparisons during re-ranking, lost feed/like state after relaunch, stale current-user group preferences, and budget filtering.
- Removed the five-comparison cap so larger ranking lists can resolve the full insertion position.
- Added 13 deterministic core tests and 3 simulator UI tests. Debug and Release simulator builds and the UI flows passed locally during this update.
