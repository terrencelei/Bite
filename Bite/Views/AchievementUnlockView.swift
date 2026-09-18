import SwiftUI

/// The achievement-unlock celebration. Tasteful, not game-y: a dimmed backdrop, a badge
/// that scales in with a soft glow, and light haptics. Legendary/epic unlocks get a
/// slightly more pronounced animation.
struct AchievementUnlockView: View {
    @Environment(AppModel.self) private var model
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showShare = false

    private var isBig: Bool { achievement.rarity >= .epic }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 18) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.caption.weight(.heavy)).tracking(2)
                    .foregroundStyle(.white.opacity(0.9))

                ZStack {
                    // Soft radial glow, stronger for rarer unlocks.
                    Circle()
                        .fill(RadialGradient(colors: [achievement.rarity.tint.opacity(isBig ? 0.7 : 0.5), .clear],
                                             center: .center, startRadius: 6, endRadius: 130))
                        .frame(width: 240, height: 240)
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)

                    AchievementBadge(achievement: achievement, unlocked: true, size: 130)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .rotationEffect(.degrees(appeared ? 0 : -12))
                }

                VStack(spacing: 6) {
                    Text(achievement.name).font(.title.bold()).foregroundStyle(.white)
                    RarityChip(rarity: achievement.rarity)
                    Text(achievement.description)
                        .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(appeared ? 1 : 0)

                HStack(spacing: 12) {
                    Button { onDismiss() } label: {
                        Text("View Achievement").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered).tint(.white)

                    Button { showShare = true } label: {
                        Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(achievement.rarity.tint)
                }
                .padding(.horizontal, 30)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)
            }
            .padding(.vertical, 30)
        }
        .onAppear {
            withAnimation(.spring(response: isBig ? 0.6 : 0.45, dampingFraction: isBig ? 0.55 : 0.7)) {
                appeared = true
            }
            isBig ? Haptics.celebrate() : Haptics.success()
        }
        .sheet(isPresented: $showShare) {
            ShareCardSheet { AchievementShareCard(achievement: achievement) }
        }
    }
}
