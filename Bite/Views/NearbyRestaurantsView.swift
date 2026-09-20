import SwiftUI

struct NearbyRestaurantsView: View {
    @Environment(AppModel.self) private var model
    @Environment(NearbySearchStore.self) private var nearby

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Find your next bite").font(.largeTitle.bold())
                Text("Explore real restaurants, save places for later, and rank the ones you’ve visited.")
                    .foregroundStyle(.secondary)
                NearbySearchControls()
                if nearby.isLoading { ProgressView("Finding restaurants…").frame(maxWidth: .infinity) }
                if !nearby.results.isEmpty {
                    HStack {
                        Text(nearby.areaName).font(.headline)
                        Spacer()
                        Text("\(nearby.results.count) places").foregroundStyle(.secondary)
                    }
                    Text("Results from Apple Maps. Search a name or cuisine, or move the map to discover more.")
                        .font(.caption).foregroundStyle(.secondary)
                    LazyVStack(spacing: 12) {
                        ForEach(nearby.results) { r in
                            NavigationLink(value: r) { RestaurantRow(restaurant: r).padding(12).cardSurface() }
                                .buttonStyle(.plain).accessibilityIdentifier("restaurantResult")
                        }
                    }
                } else if nearby.didSearch {
                    ContentUnavailableView("No restaurants found", systemImage: "fork.knife",
                        description: Text("Try a different search, expand the map area, or explore another neighborhood."))
                } else if !nearby.isLoading {
                    ContentUnavailableView("Where would you like to eat?", systemImage: "map",
                        description: Text("Use your location or enter a city or neighborhood above."))
                }
            }
            .padding()
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .biteDestinations()
        .refreshable { if nearby.hasArea { nearby.search(model: model) } }
    }
}

struct NearbySearchControls: View {
    @Environment(AppModel.self) private var model
    @Environment(NearbySearchStore.self) private var nearby
    @Environment(\.openURL) private var openURL
    @State private var area = ""
    @FocusState private var focusedField: Field?
    private enum Field { case area, restaurant }

    var body: some View {
        @Bindable var nearby = nearby
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("City, neighborhood, or address", text: $area)
                    .textFieldStyle(.roundedBorder).submitLabel(.search)
                    .accessibilityIdentifier("areaSearchField")
                    .focused($focusedField, equals: .area)
                    .onSubmit { searchArea() }
                Button(action: searchArea) { Image(systemName: "magnifyingglass") }
                    .accessibilityLabel("Search location")
                    .disabled(area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            HStack {
                TextField("Restaurant name or cuisine", text: $nearby.query)
                    .textFieldStyle(.roundedBorder).submitLabel(.search)
                    .accessibilityIdentifier("restaurantSearchField")
                    .focused($focusedField, equals: .restaurant)
                    .onSubmit { searchRestaurants() }
                Button(action: searchRestaurants) { Image(systemName: "arrow.right.circle.fill") }
                    .accessibilityLabel("Search restaurants").disabled(!nearby.hasArea)
            }
            Button { focusedField = nil; nearby.useMyLocation(model: model) } label: {
                Label(nearby.location.isLocating ? "Finding your location…" : "Near me", systemImage: "location.fill")
            }
            .buttonStyle(.bordered).disabled(nearby.location.isLocating)
            if let message = nearby.location.message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
                if nearby.location.permissionDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }.font(.footnote)
                }
            }
            if let error = nearby.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
                if nearby.hasArea { Button("Retry") { nearby.search(model: model) } }
            }
        }
    }

    private func searchArea() {
        focusedField = nil
        nearby.findArea(area, model: model)
    }
    private func searchRestaurants() {
        focusedField = nil
        nearby.search(model: model)
    }
}

struct SavedRestaurantsView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        Group {
            let saved = model.restaurants.filter { model.isWantToTry($0.id) }
            if saved.isEmpty {
                ContentUnavailableView("Your next bites", systemImage: "bookmark",
                    description: Text("Save restaurants from Discover or Map to find them here, even offline."))
            } else {
                List(saved) { r in
                    NavigationLink(value: r) { RestaurantRow(restaurant: r) }.accessibilityIdentifier("savedRestaurant")
                }
            }
        }
        .navigationTitle("Saved")
        .biteDestinations()
    }
}
