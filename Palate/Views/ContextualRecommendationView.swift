import SwiftUI

/// The playful "What are you looking for?" flow. Deliberately not a search form — big
/// tappable options — then 3–5 explained recommendations.
struct ContextualRecommendationView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var presetOccasion: Occasion?

    @State private var context = RecommendationContext.empty
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            Group {
                if showResults {
                    resultsList
                } else {
                    configForm
                }
            }
            .navigationTitle(showResults ? "For You Tonight" : "What are you looking for?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showResults ? "Back" : "Cancel") {
                        if showResults { withAnimation { showResults = false } } else { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            if let presetOccasion { context.occasion = presetOccasion }
            context.cityID = model.homeCityID
        }
        .presentationDetents(showResults ? [.large] : [.medium, .large])
    }

    // MARK: Config

    private var configForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                pickerBlock("Occasion") {
                    chipWrap(Occasion.allCases, selected: context.occasion) { occ in
                        CuisineChip(text: occ.label, symbol: occ.symbol,
                                    isSelected: context.occasion == occ) {
                            context.occasion = context.occasion == occ ? nil : occ
                        }
                    }
                }

                pickerBlock("Cuisine") {
                    chipWrap(cuisineFamilies, selected: context.cuisineFamily) { fam in
                        CuisineChip(text: fam, isSelected: context.cuisineFamily == fam) {
                            context.cuisineFamily = context.cuisineFamily == fam ? nil : fam
                        }
                    }
                }

                budgetBlock
                vibeBlock

                Stepper("Party of \(context.partySize)", value: $context.partySize, in: 1...12)
                    .padding(.horizontal)

                Toggle("New restaurants only", isOn: $context.newRestaurantsOnly)
                    .padding(.horizontal)

                Button {
                    Haptics.tap()
                    withAnimation(.spring) { showResults = true }
                } label: {
                    Text("Show me").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.accent)
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .padding(.vertical)
        }
    }

    private var budgetBlock: some View {
        pickerBlock("Budget") {
            HStack(spacing: 10) {
                ForEach(PriceLevel.allCases, id: \.self) { p in
                    let sel = context.maxPrice == p
                    CuisineChip(text: p.display(currency: model.currency(for: context.cityID ?? "sf")),
                                isSelected: sel) {
                        context.maxPrice = sel ? nil : p
                    }
                }
            }
        }
    }

    private var vibeBlock: some View {
        pickerBlock("Vibe") {
            HStack(spacing: 10) {
                CuisineChip(text: "Casual", symbol: "sun.max", isSelected: context.upscale == false) {
                    context.upscale = context.upscale == false ? nil : false
                }
                CuisineChip(text: "Upscale", symbol: "sparkles", isSelected: context.upscale == true) {
                    context.upscale = context.upscale == true ? nil : true
                }
            }
        }
    }

    // MARK: Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                let results = computedResults
                if results.isEmpty {
                    ContentUnavailableView("No matches yet",
                                           systemImage: "fork.knife",
                                           description: Text("Try loosening a filter — fewer constraints, more taste."))
                        .padding(.top, 40)
                }
                ForEach(results) { rec in
                    if let r = model.restaurant(rec.restaurantID) {
                        NavigationLink(value: r) {
                            ContextResultCard(restaurant: r, recommendation: rec)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .palateDestinations()
    }

    private var computedResults: [Recommendation] {
        var pool = model.restaurants
        if let city = context.cityID { pool = pool.filter { $0.cityID == city } }
        return model.recommendations(context: context, candidates: pool,
                                     excludeVisited: context.newRestaurantsOnly, limit: 5)
    }

    // MARK: Building blocks

    private var cuisineFamilies: [String] {
        Array(Set(model.restaurants.map { $0.cuisine.family })).sorted()
    }

    private func pickerBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.caption.weight(.bold)).tracking(0.5)
                .foregroundStyle(.secondary).padding(.horizontal)
            content().padding(.horizontal)
        }
    }

    private func chipWrap<T: Hashable, V: View>(_ items: [T], selected: T?, @ViewBuilder chip: @escaping (T) -> V) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { chip($0) }
        }
    }
}

/// Result card that leads with the match and lists the "great for tonight because" reasons.
struct ContextResultCard: View {
    @Environment(AppModel.self) private var model
    let restaurant: Restaurant
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RestaurantImage(restaurant: restaurant, height: 150)
                MatchBadge(score: recommendation.matchScore, size: .large).padding(10)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(restaurant.name).font(.title3.bold())
                    Spacer()
                    PriceText(price: restaurant.price, currency: model.currency(for: restaurant.cityID))
                }
                Text("\(restaurant.cuisine.label) · \(restaurant.neighborhood)")
                    .font(.subheadline).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recommendation.reasons, id: \.self) { reason in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption).foregroundStyle(Theme.matchColor(recommendation.matchScore))
                            Text(reason).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(14)
        }
        .cardSurface()
    }
}
