import SwiftUI

/// The Food Passport: ranked-restaurant counts grouped by country and city, styled with
/// subtle passport/stamp motifs. Tapping a city opens its completion detail.
struct FoodPassportView: View {
    @Environment(AppModel.self) private var model
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                summary
                ForEach(model.passport()) { country in
                    countryBlock(country)
                }
                if model.passport().isEmpty { emptyState }
                Color.clear.frame(height: 8)
            }
            .padding()
        }
        .navigationTitle("Food Passport")
        .navigationBarTitleDisplayMode(.inline)
        .biteDestinations()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShare = true } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareCardSheet { PassportShareCard(userName: model.currentUser.name, countries: model.passport()) }
        }
    }

    private var summary: some View {
        let p = model.passport()
        let total = p.reduce(0) { $0 + $1.total }
        return HStack {
            ProfileStat(value: "\(total)", label: "Ranked")
            Divider().frame(height: 36)
            ProfileStat(value: "\(p.flatMap(\.cities).count)", label: "Cities")
            Divider().frame(height: 36)
            ProfileStat(value: "\(p.count)", label: "Countries")
        }
        .padding()
        .cardSurface()
    }

    private func countryBlock(_ country: PassportCountry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(country.flag).font(.title)
                Text(country.country.uppercased()).font(.headline).tracking(0.5)
                Spacer()
                Text("\(country.total)").font(.headline.monospacedDigit()).foregroundStyle(.secondary)
            }
            let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(country.cities) { city in
                    NavigationLink(value: city) {
                        PassportStamp(title: city.name, count: city.count,
                                      color: Color.seeded(city.cityID, saturation: 0.6, brightness: 0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .cardSurface()
    }

    private var emptyState: some View {
        ContentUnavailableView("Your passport is empty", systemImage: "book.closed",
                               description: Text("Your Food Passport starts with your first ranked restaurant."))
    }
}

/// City detail: neighborhood-by-neighborhood completion + that city's ranked list.
struct CityDetailView: View {
    @Environment(AppModel.self) private var model
    let cityID: String

    private var city: City? { model.city(cityID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                completion
                cityRanking
            }
            .padding()
        }
        .navigationTitle(city?.name ?? "City")
        .navigationBarTitleDisplayMode(.inline)
        .biteDestinations()
    }

    private var completion: some View {
        let rows = model.cityCompletion(cityID)
        let exploredHoods = rows.filter { $0.ranked > 0 }.count
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exploration",
                          subtitle: "\(exploredHoods)/\(rows.count) neighborhoods explored")
            ForEach(rows, id: \.neighborhood) { row in
                HStack {
                    Image(systemName: row.ranked == row.total ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(row.ranked == row.total ? .green : .secondary)
                    Text(row.neighborhood).font(.subheadline)
                    Spacer()
                    Text(row.ranked == row.total ? "✓" : "\(row.ranked)/\(row.total)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private var cityRanking: some View {
        let scope = RankingScope(kind: .city(cityID), title: city?.name ?? "", subtitle: "", symbol: "trophy.fill")
        let entries = model.entries(in: scope)
        return Group {
            if entries.isEmpty {
                ContentUnavailableView("No ranking here yet", systemImage: "list.number",
                                       description: Text("Rank a few restaurants here to start your \(city?.name ?? "city") list."))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Your \(city?.name ?? "") Ranking")
                    ForEach(Array(entries.prefix(10).enumerated()), id: \.element.entry.id) { idx, item in
                        NavigationLink(value: item.restaurant) {
                            RankingRow(position: idx + 1, restaurant: item.restaurant, isNew: item.entry.isNew)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 54)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardSurface()
            }
        }
    }
}

/// Passport share card.
struct PassportShareCard: View {
    let userName: String
    let countries: [PassportCountry]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(userName.uppercased())'S").font(.caption.weight(.heavy)).tracking(1).foregroundStyle(.white)
            Text("Food Passport").font(.title.bold()).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(countries.prefix(5)) { c in
                    HStack {
                        Text("\(c.flag) \(c.country)").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        Spacer()
                        Text("\(c.total)").font(.subheadline.bold()).foregroundStyle(.white)
                    }
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill"); Text("Bite").font(.caption.weight(.bold))
            }.foregroundStyle(.white.opacity(0.9))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Theme.indigo, Theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}
