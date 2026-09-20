import SwiftUI
import MapKit

struct MapScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(NearbySearchStore.self) private var nearby
    @State private var camera: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedID: String?
    @State private var selection: MapSelection<String>?
    @State private var loadingPlace = false
    @State private var placeError: String?
    @State private var filter: MapFilter = .restaurants
    @State private var showSearch = false

    enum MapFilter: String, CaseIterable, Identifiable {
        case restaurants = "Restaurants", saved = "Saved", been = "Been"
        var id: String { rawValue }
    }

    private var visible: [Restaurant] {
        switch filter {
        case .restaurants: return nearby.results
        case .saved: return model.restaurants.filter { model.isWantToTry($0.id) }
        case .been: return model.restaurants.filter { model.isBeen($0.id) }
        }
    }

    var body: some View {
        Map(position: $camera, selection: $selection) {
            UserAnnotation()
            ForEach(visible) { r in
                Marker(r.name, systemImage: r.cuisine.symbol, coordinate: r.coordinate.clLocation)
                    .tint(model.isBeen(r.id) ? .green : Theme.accent).tag(MapSelection(r.id))
            }
        }
        .mapStyle(.standard(pointsOfInterest: .including([.restaurant, .cafe, .bakery])))
        .mapFeatureSelectionDisabled { feature in
            guard let category = feature.pointOfInterestCategory else { return true }
            return ![MKPointOfInterestCategory.restaurant, .cafe, .bakery].contains(category)
        }
        .task(id: selection) { await loadSelection() }
        .onMapCameraChange(frequency: .onEnd) { context in visibleRegion = context.region }
        .mapControls { MapCompass(); MapScaleView() }
        .safeAreaInset(edge: .top) { controls }
        .safeAreaInset(edge: .bottom) { bottomCard }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .biteDestinations()
        .onAppear { camera = .region(nearby.region) }
        .onChange(of: nearby.regionRevision) { _, _ in
            selectedID = nil; selection = nil
            camera = .region(nearby.region)
        }
         .onChange(of: filter) { _, newFilter in
            selectedID = nil; selection = nil
            if newFilter != .restaurants, !visible.isEmpty { camera = .automatic }
            else if nearby.hasArea { camera = .region(nearby.region) }
        }
        .onChange(of: nearby.results.map(\.id)) { _, _ in selectedID = nil; selection = nil }
        .sheet(isPresented: $showSearch) {
            NavigationStack {
                ScrollView { NearbySearchControls().padding() }
                    .navigationTitle("Search an area")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSearch = false } } }
            }
            .presentationDetents([.medium, .large])
        }
    }

    /// Native restaurant POIs remain tappable even when omitted from a search response.
    @MainActor private func loadSelection() async {
        selectedID = selection?.value
        placeError = nil
        loadingPlace = false
        guard let feature = selection?.feature else { return }
        let token = selection
        let request = MKMapItemRequest(feature: feature)
        loadingPlace = true
        defer { if selection == token { loadingPlace = false } }
        do {
            let item = try await withTaskCancellationHandler {
                try await request.mapItem
            } onCancel: {
                Task { @MainActor in request.cancel() }
            }
            guard !Task.isCancelled, selection == token else { return }
            if let (restaurant, city) = AppleRestaurantSearch.map(item) {
                model.mergeListings([restaurant], cities: [city])
                selectedID = restaurant.id
            }
        } catch {
            if !Task.isCancelled, selection == token {
                placeError = "Couldn’t load this restaurant. Check your connection and tap it again."
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack {
                Button { showSearch = true } label: { Label("Search", systemImage: "magnifyingglass") }
                Spacer()
                Button { nearby.useMyLocation(model: model) } label: {
                    Label(nearby.location.isLocating ? "Locating…" : "Near me", systemImage: "location.fill")
                }.disabled(nearby.location.isLocating)
            }
            Picker("Places", selection: $filter) {
                ForEach(MapFilter.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            if filter == .restaurants {
                Button {
                    selectedID = nil; selection = nil
                    nearby.search(in: visibleRegion ?? nearby.region, model: model)
                } label: { Label("Search this area", systemImage: "arrow.clockwise") }
                    .buttonStyle(.borderedProminent).tint(Theme.accent)
                    .disabled(nearby.isLoading)
            }
        }
        .padding(12).background(.regularMaterial)
    }

    @ViewBuilder private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if loadingPlace {
                ProgressView("Loading restaurant…")
            } else if let error = placeError {
                Text(error).font(.footnote)
            } else if let id = selectedID, let r = model.restaurant(id) {
                NavigationLink(value: r) { RestaurantRow(restaurant: r) }.buttonStyle(.plain)
            } else if nearby.isLoading {
                ProgressView("Finding restaurants…")
            } else if let error = nearby.errorMessage {
                Text(error).font(.footnote)
                Button("Search another area") { showSearch = true }
            } else if let message = nearby.location.message {
                Text(message).font(.footnote)
                Button("Location options") { showSearch = true }
            } else {
                Text(filter == .restaurants ? "\(visible.count) restaurants found" : "\(visible.count) places")
                    .font(.subheadline.bold())
                Text(filter == .restaurants
                     ? "Search this area or a restaurant name to find more. Results may not include every restaurant."
                     : "Tap a pin to view a restaurant.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().background(.regularMaterial)
    }
}
