import SwiftUI

/// The signature personalization element: a bold, colored match score. Intentionally
/// louder than any star rating — match % is the product's primary quality signal.
struct MatchBadge: View {
    let score: Double
    var size: Size = .regular

    enum Size { case small, regular, large }

    private var color: Color { Theme.matchColor(score) }

    private var font: Font {
        switch size {
        case .small: return .caption.bold()
        case .regular: return .subheadline.bold()
        case .large: return .title3.bold()
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(score.asPercent).font(font).monospacedDigit()
            Text("MATCH").font(.system(size: size == .large ? 11 : 9, weight: .heavy)).tracking(0.5)
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, size == .large ? 12 : 9)
        .padding(.vertical, size == .large ? 7 : 5)
        .background(color, in: Capsule())
        .shadow(color: color.opacity(0.35), radius: 6, y: 3)
    }
}

/// A circular match ring used on detail headers where a large, glanceable score fits.
struct MatchRing: View {
    let score: Double
    var diameter: CGFloat = 68
    private var color: Color { Theme.matchColor(score) }

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: 6)
            Circle().trim(from: 0, to: score)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int((score * 100).rounded()))").font(.system(size: diameter * 0.3, weight: .bold)).monospacedDigit()
                Text("MATCH").font(.system(size: diameter * 0.12, weight: .heavy)).tracking(0.5).foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

/// A subtle rarity chip for achievements.
struct RarityChip: View {
    let rarity: AchievementRarity
    var body: some View {
        Text(rarity.label.uppercased())
            .font(.system(size: 9, weight: .heavy)).tracking(0.6)
            .foregroundStyle(rarity.tint)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(rarity.tint.opacity(0.14), in: Capsule())
    }
}

/// Price glyphs ("¥¥¥") rendered with a dimmed "unused" tail for clarity.
struct PriceText: View {
    let price: PriceLevel
    let currency: String
    var body: some View {
        Group {
            if price == .unknown {
                Text("Price unavailable").font(.caption).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 0) {
                    Text(String(repeating: currency, count: price.rawValue)).foregroundStyle(.primary)
                    Text(String(repeating: currency, count: 4 - price.rawValue)).foregroundStyle(.quaternary)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MatchBadge(score: 0.94, size: .large)
        MatchBadge(score: 0.82)
        MatchBadge(score: 0.61, size: .small)
        MatchRing(score: 0.94)
        RarityChip(rarity: .legendary)
        PriceText(price: .upscale, currency: "¥")
    }
    .padding()
}
