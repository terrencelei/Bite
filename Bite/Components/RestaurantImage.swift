import SwiftUI

/// An illustrative placeholder, not a photograph of the restaurant.
/// Stable colors keep a saved place recognizable without inventing imagery.
struct RestaurantImage: View {
    let restaurant: Restaurant
    var height: CGFloat? = nil
    var corner: CGFloat = Theme.cardRadius

    private var pair: (Color, Color) { Color.seededPair(restaurant.id + restaurant.name) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)

            // Soft radial highlight for depth.
            RadialGradient(colors: [.white.opacity(0.28), .clear],
                           center: .topLeading, startRadius: 4, endRadius: 220)

            // Cuisine glyph watermark.
            Image(systemName: restaurant.cuisine.symbol)
                .font(.system(size: (height ?? 180) * 0.42, weight: .regular))
                .foregroundStyle(.white.opacity(0.22))
                .rotationEffect(.degrees(-8))
                .offset(x: 8, y: 6)

            // Bottom scrim so overlaid text stays legible.
            LinearGradient(colors: [.clear, .black.opacity(0.28)], startPoint: .center, endPoint: .bottom)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(alignment: .topTrailing) { badges }
    }

    /// Michelin / landmark markers float on the image.
    @ViewBuilder private var badges: some View {
        HStack(spacing: 6) {
            if restaurant.isMichelin {
                Label("\(restaurant.michelinStars)", systemImage: "star.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2.bold())
                    .padding(.horizontal, 7).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            if restaurant.isTrending {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2.bold())
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(10)
        .foregroundStyle(.white)
    }
}

/// A small circular thumbnail variant for rows and lists.
struct RestaurantThumb: View {
    let restaurant: Restaurant
    var size: CGFloat = 56
    private var pair: (Color, Color) { Color.seededPair(restaurant.id + restaurant.name) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: restaurant.cuisine.symbol)
                .font(.system(size: size * 0.4))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}
