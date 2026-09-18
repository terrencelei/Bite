import SwiftUI

/// Procedural friend avatar — an emoji/monogram on a seeded gradient. Offline-safe and
/// gives every user a stable identity color.
struct FriendAvatar: View {
    let user: User
    var size: CGFloat = 44
    var showRing: Bool = false
    var ringColor: Color = Theme.accent

    private var pair: (Color, Color) { Color.seededPair(user.id) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(user.monogram).font(.system(size: size * 0.5))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showRing { Circle().strokeBorder(ringColor, lineWidth: 2) }
        }
    }
}

/// A ring visualization of a taste-match percentage, with the two avatars implied by color.
struct TasteMatchView: View {
    let match: Double
    var diameter: CGFloat = 92
    var caption: String = "TASTE MATCH"

    private var color: Color { Theme.indigo }

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 8)
            Circle().trim(from: 0, to: match)
                .stroke(LinearGradient(colors: [Theme.accent, color], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(match.asPercent).font(.system(size: diameter * 0.26, weight: .bold)).monospacedDigit()
                Text(caption).font(.system(size: diameter * 0.1, weight: .heavy)).tracking(0.5)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

#Preview {
    HStack {
        FriendAvatar(user: Users.jason, size: 60, showRing: true)
        TasteMatchView(match: 0.94)
    }
    .padding()
}
