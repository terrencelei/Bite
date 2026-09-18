import SwiftUI

/// The primary Discover card: a hero image, prominent match badge, and a personalized
/// one-line reason. Designed to read at a glance in a horizontal carousel.
struct RestaurantCard: View {
    @Environment(AppModel.self) private var model
    let restaurant: Restaurant
    var recommendation: Recommendation? = nil
    var width: CGFloat? = 290

    private var currency: String { model.currency(for: restaurant.cityID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RestaurantImage(restaurant: restaurant, height: 172, corner: Theme.cardRadius)
                if let rec = recommendation {
                    MatchBadge(score: rec.matchScore).padding(10)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(restaurant.name).font(.headline).lineLimit(1)
                    Spacer(minLength: 6)
                    PriceText(price: restaurant.price, currency: currency)
                }
                Text("\(restaurant.cuisine.label) · \(restaurant.neighborhood)")
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)

                if let reason = recommendation?.reasons.first {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 1)
                }

                friendRow
            }
            .padding(12)
        }
        .frame(width: width)
        .cardSurface()
    }

    /// Surfaces a supporting friend if the recommendation cited one.
    @ViewBuilder private var friendRow: some View {
        if let fid = recommendation?.supportingFriendIDs.first, let friend = model.user(fid) {
            HStack(spacing: 6) {
                FriendAvatar(user: friend, size: 22)
                Text("\(friend.name) · \(model.tasteMatch(friend).asPercent) match")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            .padding(.top, 2)
        }
    }
}

/// A compact horizontal row variant used in lists (Near You, search results, map sheet).
struct RestaurantRow: View {
    @Environment(AppModel.self) private var model
    let restaurant: Restaurant
    var recommendation: Recommendation? = nil

    var body: some View {
        HStack(spacing: 12) {
            RestaurantThumb(restaurant: restaurant, size: 60)
            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text("\(restaurant.cuisine.label) · \(restaurant.neighborhood)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 6) {
                    PriceText(price: restaurant.price, currency: model.currency(for: restaurant.cityID))
                        .font(.caption)
                    if restaurant.isMichelin {
                        Label("Michelin", systemImage: "star.circle.fill")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                }
            }
            Spacer(minLength: 4)
            if let rec = recommendation {
                MatchBadge(score: rec.matchScore, size: .small)
            } else if let entry = model.ranking(for: restaurant.id) {
                // Show its rank if already ranked.
                Text("#\(model.overallRank(of: entry) ?? 0)")
                    .font(.subheadline.bold()).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
