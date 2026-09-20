import SwiftUI
import MapKit

/// Rich restaurant page: hero, match + reasons, save/been actions, dishes, friend
/// activity, ranking context, and a map. Star ratings are intentionally absent — the
/// personalized match is the quality signal.
struct RestaurantDetailView: View {
    @Environment(AppModel.self) private var model
    let restaurant: Restaurant

    @State private var showRankingFlow = false

    private var recommendation: Recommendation? { model.recommendation(for: restaurant.id) }
    private var currency: String { model.currency(for: restaurant.cityID) }
    private var city: City? { model.city(restaurant.cityID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                titleBlock.padding(.horizontal)
                actionButtons.padding(.horizontal)
                if isRanked { rankingContext.padding(.horizontal) }
                whyYoullLikeIt.padding(.horizontal)
                if !restaurant.dishes.isEmpty { dishes }
                if let listing = restaurant.listing { listingDetails(listing).padding(.horizontal) }
                friendActivity.padding(.horizontal)
                mapBlock.padding(.horizontal)
                Color.clear.frame(height: 16)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showRankingFlow) {
            RankingFlowView(restaurant: restaurant)
        }
    }

    private var isRanked: Bool { model.isBeen(restaurant.id) }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RestaurantImage(restaurant: restaurant, height: 320, corner: 0)
            if let rec = recommendation {
                MatchBadge(score: rec.matchScore, size: .large)
                    .padding(16)
            }
        }
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(restaurant.name).font(.largeTitle.bold())
            Text("\(restaurant.cuisine.label) · \(restaurant.subCuisine)")
                .font(.headline).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Label("\(restaurant.neighborhood), \(city?.name ?? "")", systemImage: "mappin.circle.fill")
                    .foregroundStyle(.secondary)
                Text("·").foregroundStyle(.secondary)
                PriceText(price: restaurant.price, currency: currency)
                if let flag = city?.countryFlag { Text(flag) }
            }
            .font(.subheadline)

            if restaurant.isMichelin || restaurant.isLandmark {
                HStack(spacing: 8) {
                    if restaurant.isMichelin {
                        Label("\(restaurant.michelinStars) Michelin ★ (mock)", systemImage: "star.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    if restaurant.isLandmark {
                        Label("Landmark", systemImage: "seal.fill").foregroundStyle(Theme.accent)
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.top, 2)
            }
        }
    }

    // MARK: Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                model.toggleWantToTry(restaurant.id)
            } label: {
                Label(model.isWantToTry(restaurant.id) ? "Saved" : "Want to Try",
                      systemImage: model.isWantToTry(restaurant.id) ? "bookmark.fill" : "bookmark")
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("saveRestaurant")
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Theme.accent)

            Button {
                Haptics.tap()
                showRankingFlow = true
            } label: {
                Label(isRanked ? "Re-rank" : "Been", systemImage: isRanked ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("rankRestaurant")
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
        }
    }

    // MARK: Ranking context

    @ViewBuilder private var rankingContext: some View {
        if let entry = model.ranking(for: restaurant.id) {
            let cityScope = RankingScope(kind: .city(restaurant.cityID), title: "", subtitle: "", symbol: "")
            let cityRank = model.rank(of: restaurant.id, in: cityScope) ?? 0
            HStack(spacing: 14) {
                VStack {
                    Text("#\(cityRank)").font(.title.bold())
                    Text("in \(city?.name ?? "")").font(.caption).foregroundStyle(.secondary)
                }
                Divider().frame(height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text("You've been here").font(.subheadline.weight(.semibold))
                    Text("Ranked \(entry.dateRanked.relativeShort) · \(entry.comparisons) comparisons")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .cardSurface()
        }
    }

    // MARK: Why You'll Like It

    @ViewBuilder private var whyYoullLikeIt: some View {
        if let rec = recommendation {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Why You'll Like It").sectionTitleStyle()
                    Spacer()
                    MatchRing(score: rec.matchScore, diameter: 56)
                }
                ForEach(rec.reasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkle").foregroundStyle(Theme.accent).font(.footnote)
                        Text(reason).font(.subheadline)
                    }
                }
                Text(restaurant.blurb).font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
            }
            .padding(16)
            .cardSurface()
        }
    }

    // MARK: Dishes

    private var dishes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Dishes").sectionTitleStyle().padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(restaurant.dishes) { dish in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LinearGradient(colors: [Color.seededPair(dish.name).0, Color.seededPair(dish.name).1],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 160, height: 100)
                                    .overlay(Image(systemName: "fork.knife").font(.title).foregroundStyle(.white.opacity(0.5)))
                                if dish.isSignature {
                                    Text("SIGNATURE").font(.system(size: 8, weight: .heavy))
                                        .padding(.horizontal, 6).padding(.vertical, 3)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .padding(6)
                                }
                            }
                            Text(dish.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                            Text(dish.note).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                .frame(width: 160, alignment: .leading)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Friend activity

    @ViewBuilder private var friendActivity: some View {
        let activity = model.friendsWithActivity(for: restaurant.id)
        if !activity.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Friend Activity").sectionTitleStyle()
                ForEach(activity, id: \.user.id) { item in
                    NavigationLink(value: item.user) {
                        HStack(spacing: 10) {
                            FriendAvatar(user: item.user, size: 36)
                            Text("**\(item.user.name)** \(item.label)")
                                .font(.subheadline).foregroundStyle(.primary)
                            Spacer()
                            Text(model.tasteMatch(item.user).asPercent)
                                .font(.caption.weight(.semibold)).foregroundStyle(Theme.indigo)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .cardSurface()
        }
    }

    // MARK: Map

    private var mapBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location").sectionTitleStyle()
            Map(initialPosition: .region(MKCoordinateRegion(
                center: restaurant.coordinate.clLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))) {
                    Marker(restaurant.name, systemImage: restaurant.cuisine.symbol,
                           coordinate: restaurant.coordinate.clLocation)
                        .tint(Theme.accent)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)
        }
    }

    private func listingDetails(_ listing: RestaurantListing) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Visit this restaurant").sectionTitleStyle()
            if !listing.address.isEmpty { Label(listing.address, systemImage: "mappin.and.ellipse").textSelection(.enabled) }
            if let phone = listing.phone {
                Text(phone).textSelection(.enabled)
            }
            if let url = listing.website { Link(destination: url) { Label("Website", systemImage: "globe") } }
            if let url = listing.mapsURL { Link(destination: url) { Label("Open in Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond") } }
            Text("Place information from Apple Maps. Check the restaurant’s website for current hours, menu, and prices.")
                .font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding().cardSurface()
    }

    private var shareText: String {
        "\(restaurant.name) — \(restaurant.listing?.address ?? restaurant.neighborhood)\n\(restaurant.listing?.mapsURL?.absoluteString ?? "Saved on Bite")"
    }
}
