import SwiftUI

/// Central design system for Bite.
///
/// The visual identity leans on warm, appetite-forward tones (a saffron/coral accent)
/// balanced by generous neutrals so restaurant photography stays the hero. Everything
/// here adapts automatically to light & dark mode.
enum Theme {

    // MARK: Brand color

    /// Primary brand accent — a warm saffron-coral. Mirrors `AccentColor` in the asset catalog.
    static let accent = Color("AccentColor")

    /// Secondary brand tone used for gradients and highlights.
    static let secondaryAccent = Color(red: 0.98, green: 0.58, blue: 0.28)

    /// A cool contrast tone used sparingly (taste-match, social).
    static let indigo = Color(red: 0.36, green: 0.34, blue: 0.86)

    // MARK: Semantic surfaces

    static let card = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let separator = Color(.separator)

    // MARK: Match-score coloring

    /// Returns a color that communicates the strength of a match/score (0...1).
    static func matchColor(_ score: Double) -> Color {
        switch score {
        case 0.90...:      return Color(red: 0.12, green: 0.72, blue: 0.45)   // exceptional — green
        case 0.80..<0.90:  return Color(red: 0.20, green: 0.66, blue: 0.52)
        case 0.70..<0.80:  return accent                                       // strong — brand
        case 0.55..<0.70:  return secondaryAccent
        default:           return Color(.systemGray)
        }
    }

    // MARK: Corner radii

    static let cardRadius: CGFloat = 20
    static let chipRadius: CGFloat = 14
    static let heroRadius: CGFloat = 26
}

// MARK: - Rarity styling

extension AchievementRarity {
    var tint: Color {
        switch self {
        case .common:    return Color(.systemGray)
        case .uncommon:  return Color(red: 0.20, green: 0.66, blue: 0.52)
        case .rare:      return Color(red: 0.24, green: 0.52, blue: 0.96)
        case .epic:      return Color(red: 0.56, green: 0.36, blue: 0.92)
        case .legendary: return Color(red: 0.92, green: 0.66, blue: 0.18)
        }
    }

    var label: String {
        switch self {
        case .common:    return "Common"
        case .uncommon:  return "Uncommon"
        case .rare:      return "Rare"
        case .epic:      return "Epic"
        case .legendary: return "Legendary"
        }
    }
}

// MARK: - Reusable view modifiers

/// A soft, rounded card surface with a hairline border — the workhorse container.
struct CardSurface: ViewModifier {
    var radius: CGFloat = Theme.cardRadius
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    func cardSurface(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(CardSurface(radius: radius))
    }

    /// Section header styling used across scrolling surfaces.
    func sectionTitleStyle() -> some View {
        font(.title3.weight(.bold))
    }
}

// MARK: - Haptics

/// Thin wrapper so haptics are tasteful, centralized, and easy to disable.
enum Haptics {
    static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func select() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func celebrate() {
        #if os(iOS)
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        #endif
    }
}
