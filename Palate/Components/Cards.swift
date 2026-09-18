import SwiftUI

// MARK: - Ranking leaderboard row

/// A single row in a ranking leaderboard, with a prominent position number.
struct RankingRow: View {
    @Environment(AppModel.self) private var model
    let position: Int
    let restaurant: Restaurant
    var isNew: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("\(position)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(position <= 3 ? Theme.accent : .secondary)
                .frame(width: 30, alignment: .center)

            RestaurantThumb(restaurant: restaurant, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(restaurant.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    if isNew {
                        Text("NEW").font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
                    }
                }
                Text("\(restaurant.cuisine.label) · \(restaurant.neighborhood)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            PriceText(price: restaurant.price, currency: model.currency(for: restaurant.cityID))
                .font(.caption)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Social activity card

/// One item in the social feed, rendering different verbs for each activity kind.
struct SocialActivityCard: View {
    @Environment(AppModel.self) private var model
    let activity: SocialActivity

    private var author: User? { model.user(activity.userID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let author {
                    NavigationLink(value: author) { FriendAvatar(user: author, size: 40) }
                        .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 2) {
                    headline
                    Text(activity.date.relativeShort).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                icon
            }

            if let r = referencedRestaurant {
                NavigationLink(value: r) {
                    RestaurantRow(restaurant: r, recommendation: model.recommendation(for: r.id))
                }
                .buttonStyle(.plain)
                .padding(10)
                .background(Theme.groupedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let ach = referencedAchievement {
                achievementChip(ach)
            }

            actionBar
        }
        .padding(14)
        .cardSurface()
    }

    private var referencedRestaurant: Restaurant? {
        activity.referencedRestaurantID.flatMap { model.restaurant($0) }
    }
    private var referencedAchievement: Achievement? {
        activity.referencedAchievementID.flatMap { model.achievementByID[$0] }
    }

    @ViewBuilder private var headline: some View {
        let name = author?.name ?? "Someone"
        switch activity.kind {
        case .ranked(_, let pos, let scope):
            Text("\(name) ranked \(referencedRestaurant?.name ?? "a spot") #\(pos) in \(scope).")
                .font(.subheadline).fontWeight(.medium)
        case .newFavorite:
            Text("\(name) discovered a new favorite.").font(.subheadline).fontWeight(.medium)
        case .wantToTry:
            Text("\(name) wants to try \(referencedRestaurant?.name ?? "a spot").")
                .font(.subheadline).fontWeight(.medium)
        case .earnedAchievement:
            Text("\(name) earned \(referencedAchievement?.name ?? "an achievement").")
                .font(.subheadline).fontWeight(.medium)
        case .earlyDiscovery:
            Text("\(name) was early to \(referencedRestaurant?.name ?? "a spot") before it trended.")
                .font(.subheadline).fontWeight(.medium)
        }
    }

    private var icon: some View {
        Group {
            switch activity.kind {
            case .ranked: Image(systemName: "list.number")
            case .newFavorite: Image(systemName: "heart.fill").foregroundStyle(.pink)
            case .wantToTry: Image(systemName: "bookmark.fill").foregroundStyle(Theme.accent)
            case .earnedAchievement: Image(systemName: "rosette").foregroundStyle(.orange)
            case .earlyDiscovery: Image(systemName: "sparkle.magnifyingglass").foregroundStyle(Theme.indigo)
            }
        }
        .font(.headline).foregroundStyle(.secondary)
    }

    private func achievementChip(_ ach: Achievement) -> some View {
        HStack(spacing: 10) {
            AchievementBadge(achievement: ach, unlocked: true, size: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(ach.name).font(.subheadline.weight(.semibold))
                RarityChip(rarity: ach.rarity)
            }
            Spacer()
        }
        .padding(10)
        .background(Theme.groupedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var actionBar: some View {
        HStack(spacing: 22) {
            Button { model.toggleLike(activity.id) } label: {
                Label("\(activity.likeCount)", systemImage: activity.likedByCurrentUser ? "heart.fill" : "heart")
                    .foregroundStyle(activity.likedByCurrentUser ? .pink : .secondary)
            }
            Label("\(activity.commentCount)", systemImage: "bubble.right")
                .foregroundStyle(.secondary)
            if let r = referencedRestaurant {
                Button { model.toggleWantToTry(r.id) } label: {
                    Label(model.isWantToTry(r.id) ? "Saved" : "Save",
                          systemImage: model.isWantToTry(r.id) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(model.isWantToTry(r.id) ? Theme.accent : .secondary)
                }
            }
            Spacer()
        }
        .font(.subheadline)
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement badge & progress

/// A collectible badge — an SF Symbol on a rarity-tinted material medallion.
struct AchievementBadge: View {
    let achievement: Achievement
    var unlocked: Bool = true
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(unlocked ? achievement.rarity.tint.opacity(0.16) : Color(.tertiarySystemFill))
            Circle()
                .strokeBorder(unlocked ? achievement.rarity.tint.opacity(0.55) : Color(.separator),
                              lineWidth: unlocked ? 1.5 : 1)
            Image(systemName: unlocked ? achievement.symbol : "lock.fill")
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(unlocked ? achievement.rarity.tint : Color.secondary)
        }
        .frame(width: size, height: size)
        .opacity(unlocked ? 1 : 0.7)
    }
}

/// A progress card toward an achievement, with a bar and "X more" copy.
struct AchievementProgressCard: View {
    let achievement: Achievement
    let progress: AchievementProgress

    var body: some View {
        HStack(spacing: 12) {
            AchievementBadge(achievement: achievement, unlocked: progress.isUnlocked, size: 52)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(achievement.name).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(progress.current)/\(progress.target)")
                        .font(.caption.weight(.semibold).monospacedDigit()).foregroundStyle(.secondary)
                }
                ProgressView(value: progress.fraction).tint(achievement.rarity.tint)
                Text(progress.isUnlocked ? "Unlocked" : "\(progress.remaining) more to unlock")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .cardSurface()
    }
}

// MARK: - Passport stamp & profile stat

/// A passport-style circular stamp for a city.
struct PassportStamp: View {
    let title: String
    let count: Int
    var color: Color = Theme.accent

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.bold().monospacedDigit())
            Text(title.uppercased()).font(.system(size: 9, weight: .heavy)).tracking(0.5)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(color)
        .frame(width: 92, height: 92)
        .background(
            Circle().strokeBorder(color.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
        )
        .rotationEffect(.degrees(-6))
    }
}

/// A labeled statistic used across profiles.
struct ProfileStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
