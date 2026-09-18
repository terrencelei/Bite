import SwiftUI

/// A reusable sheet that presents a polished share card with a native ShareLink that
/// renders the card to an image. Works into iMessage, WeChat, Instagram, etc.
struct ShareCardSheet<Card: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let card: () -> Card

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                card()
                    .frame(width: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                Spacer()
                ShareLink(item: renderedImage, preview: SharePreview("Bite")) {
                    Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.accent)
                .padding(.horizontal)
            }
            .padding(.bottom)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
            .background(Theme.groupedBackground)
        }
    }

    /// Render the card to a UIImage for sharing (falls back to a small transparent image).
    @MainActor private var renderedImage: Image {
        let renderer = ImageRenderer(content:
            card().frame(width: 320).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        renderer.scale = 3
        if let ui = renderer.uiImage { return Image(uiImage: ui) }
        return Image(systemName: "photo")
    }
}

/// Warm branded backdrop shared by all cards.
private struct CardBackdrop: View {
    var body: some View {
        LinearGradient(colors: [Theme.accent, Theme.secondaryAccent],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Ranking share card

struct RankingShareCard: View {
    let scope: RankingScope
    let entries: [(entry: RankingEntry, restaurant: Restaurant)]
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(userName.uppercased() + "'S").font(.caption.weight(.heavy)).tracking(1)
                Text(scope.title).font(.title.bold())
                Text("Top \(min(entries.count, 10)) · Bite").font(.caption).opacity(0.85)
            }
            .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(Array(entries.enumerated()), id: \.element.entry.id) { idx, item in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)").font(.headline.bold().monospacedDigit())
                            .foregroundStyle(.white).frame(width: 24)
                        Text(item.restaurant.name).font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white).lineLimit(1)
                        Spacer()
                        Text(item.restaurant.cuisine.label).font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill")
                Text("Bite").font(.caption.weight(.bold))
            }
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackdrop())
    }
}

// MARK: - Taste profile share card

struct TasteProfileShareCard: View {
    let userName: String
    let traits: [String]
    let topCuisines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(userName.uppercased())'S TASTE").font(.title.bold()).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(traits, id: \.self) { t in
                    Label(t, systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(.white)
                }
            }
            Divider().overlay(.white.opacity(0.3))
            Text("TOP CUISINES").font(.caption.weight(.heavy)).tracking(1).foregroundStyle(.white.opacity(0.85))
            Text(topCuisines.joined(separator: " · ")).font(.headline).foregroundStyle(.white)
            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill")
                Text("Bite").font(.caption.weight(.bold))
            }.foregroundStyle(.white.opacity(0.9))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackdrop())
    }
}

// MARK: - Achievement share card

struct AchievementShareCard: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: achievement.symbol).font(.system(size: 60, weight: .semibold))
                .foregroundStyle(.white)
                .padding(24)
                .background(Circle().fill(.white.opacity(0.18)))
            Text(achievement.name).font(.title2.bold()).foregroundStyle(.white)
            Text(achievement.rarity.label.uppercased()).font(.caption.weight(.heavy)).tracking(1)
                .foregroundStyle(.white.opacity(0.85))
            Text(achievement.description).font(.subheadline).foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill"); Text("Bite").font(.caption.weight(.bold))
            }.foregroundStyle(.white.opacity(0.9))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(CardBackdrop())
    }
}

// MARK: - Taste match share card

struct TasteMatchShareCard: View {
    let userName: String
    let friendName: String
    let match: Double
    let commonCuisines: [String]

    var body: some View {
        VStack(spacing: 12) {
            Text(match.asPercent).font(.system(size: 64, weight: .heavy)).foregroundStyle(.white)
            Text("TASTE MATCH").font(.caption.weight(.heavy)).tracking(2).foregroundStyle(.white.opacity(0.85))
            Text("\(userName) & \(friendName)").font(.title3.bold()).foregroundStyle(.white)
            if !commonCuisines.isEmpty {
                Text("You both love " + commonCuisines.prefix(3).joined(separator: ", "))
                    .font(.subheadline).foregroundStyle(.white.opacity(0.9)).multilineTextAlignment(.center)
            }
            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill"); Text("Bite").font(.caption.weight(.bold))
            }.foregroundStyle(.white.opacity(0.9))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(CardBackdrop())
    }
}
