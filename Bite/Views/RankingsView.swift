import SwiftUI

/// Personal rankings hub: an overall list plus auto-generated contextual lists
/// (by city, cuisine, occasion), each tappable into a full, shareable leaderboard.
struct RankingsView: View {
    @Environment(AppModel.self) private var model
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", city = "City", cuisine = "Cuisine", occasion = "Occasion"
        var id: String { rawValue }
    }

    var body: some View {
        Group {
            if model.rankings.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .navigationTitle("Rankings")
        .biteDestinations()
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ForEach(filteredScopes) { scope in
                    NavigationLink(value: scope) { scopeCard(scope) }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                }
                Color.clear.frame(height: 8)
            }
            .padding(.top, 8)
        }
    }

    private var filteredScopes: [RankingScope] {
        model.availableScopes().filter { scope in
            switch filter {
            case .all: return true
            case .city: if case .city = scope.kind { return true } else { return isOverall(scope) }
            case .cuisine: if case .cuisine = scope.kind { return true } else { return isOverall(scope) }
            case .occasion: if case .occasion = scope.kind { return true } else { return isOverall(scope) }
            }
        }
    }

    private func isOverall(_ s: RankingScope) -> Bool { if case .overall = s.kind { return true }; return false }

    private func scopeCard(_ scope: RankingScope) -> some View {
        let entries = model.entries(in: scope)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(scope.title, systemImage: scope.symbol).font(.headline)
                Spacer()
                Text("\(entries.count)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            ForEach(Array(entries.prefix(3).enumerated()), id: \.element.entry.id) { idx, item in
                HStack(spacing: 10) {
                    Text("\(idx + 1)").font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(Theme.accent).frame(width: 18)
                    RestaurantThumb(restaurant: item.restaurant, size: 34)
                    Text(item.restaurant.name).font(.subheadline).lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No rankings yet", systemImage: "list.number")
        } description: {
            Text("Start ranking restaurants you've visited and we'll learn your taste.")
        } actions: {
            NavigationLink(value: model.restaurants.first!) { Text("Find something to rank") }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
        }
    }
}

/// A full leaderboard for one scope, with a share action.
struct RankingDetailView: View {
    @Environment(AppModel.self) private var model
    let scope: RankingScope
    @State private var showShare = false

    var body: some View {
        List {
            ForEach(Array(model.entries(in: scope).enumerated()), id: \.element.entry.id) { idx, item in
                NavigationLink(value: item.restaurant) {
                    RankingRow(position: idx + 1, restaurant: item.restaurant, isNew: item.entry.isNew)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(scope.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShare = true } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareCardSheet {
                RankingShareCard(scope: scope,
                                 entries: Array(model.entries(in: scope).prefix(10)),
                                 userName: model.currentUser.name)
            }
        }
    }
}
