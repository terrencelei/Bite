import SwiftUI
import MapKit

/// Map tab: restaurants plotted with distinct annotations for Been / Want to Try /
/// Recommended, a city switcher, filter toggles, and a bottom card for the selection.
struct MapScreen: View {
    @Environment(AppModel.self) private var model
    @State private var cityID = "shanghai"
    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedID: String?
    @State private var filter: MapFilter = .all

    enum MapFilter: String, CaseIterable, Identifiable {
        case all = "All", recommended = "Recommended", wantToTry = "Want to Try", been = "Been"
        var id: String { rawValue }
    }

    private var cityRestaurants: [Restaurant] {
        model.restaurants.filter { $0.cityID == cityID }
    }

    private var visible: [Restaurant] {
        cityRestaurants.filter { r in
            switch filter {
            case .all: return true
            case .recommended: return !model.isBeen(r.id)
            case .wantToTry: return model.isWantToTry(r.id)
            case .been: return model.isBeen(r.id)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            map
            controls
            if let id = selectedID, let r = model.restaurant(id) {
                selectionCard(r)
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .palateDestinations()
        .onAppear { recenter() }
        .onChange(of: cityID) { _, _ in selectedID = nil; recenter() }
    }

    private var map: some View {
        Map(position: $camera, selection: $selectedID) {
            ForEach(visible) { r in
                Marker(r.name, systemImage: r.cuisine.symbol, coordinate: r.coordinate.clLocation)
                    .tint(color(for: r))
                    .tag(r.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea(edges: .bottom)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Menu {
                ForEach(model.cities) { c in
                    Button { cityID = c.id } label: { Label("\(c.countryFlag) \(c.name)", systemImage: "mappin") }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(model.city(cityID)?.name ?? "City").fontWeight(.semibold)
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(.regularMaterial, in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MapFilter.allCases) { f in
                        CuisineChip(text: f.rawValue, isSelected: filter == f) { filter = f }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 6)
    }

    private func selectionCard(_ r: Restaurant) -> some View {
        VStack {
            Spacer()
            NavigationLink(value: r) {
                HStack(spacing: 12) {
                    RestaurantThumb(restaurant: r, size: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(r.name).font(.subheadline.weight(.semibold))
                        Text("\(r.cuisine.label) · \(r.neighborhood)").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            statusChip(for: r)
                            if model.isBeen(r.id) {
                                let scope = RankingScope(kind: .city(r.cityID), title: "", subtitle: "", symbol: "")
                                Text("#\(model.rank(of: r.id, in: scope) ?? 0) in \(model.city(r.cityID)?.name ?? "")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    if let rec = model.recommendation(for: r.id) { MatchBadge(score: rec.matchScore, size: .small) }
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder private func statusChip(for r: Restaurant) -> some View {
        if model.isBeen(r.id) {
            Label("Been", systemImage: "checkmark.circle.fill").font(.caption2).foregroundStyle(.green)
        } else if model.isWantToTry(r.id) {
            Label("Want to Try", systemImage: "bookmark.fill").font(.caption2).foregroundStyle(Theme.accent)
        } else {
            Label("Recommended", systemImage: "sparkles").font(.caption2).foregroundStyle(Theme.indigo)
        }
    }

    private func color(for r: Restaurant) -> Color {
        if model.isBeen(r.id) { return .green }
        if model.isWantToTry(r.id) { return Theme.accent }
        return Theme.indigo
    }

    private func recenter() {
        guard let c = model.city(cityID) else { return }
        camera = .region(MKCoordinateRegion(center: c.center.clLocation,
                                            span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09)))
    }
}
