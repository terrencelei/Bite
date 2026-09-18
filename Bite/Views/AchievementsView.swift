import SwiftUI

/// The achievements screen: recently unlocked, almost there, then each category.
struct AchievementsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                recentlyUnlocked
                almostThere
                ForEach(AchievementCategory.allCases) { category in
                    categorySection(category)
                }
                Color.clear.frame(height: 8)
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .biteDestinations()
    }

    // MARK: Recently unlocked

    @ViewBuilder private var recentlyUnlocked: some View {
        let recent = model.achievementsCatalog
            .compactMap { a -> (Achievement, Date)? in
                guard let d = model.progress(for: a.id)?.unlockedDate else { return nil }
                return (a, d)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(6)
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Recently Unlocked")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(recent), id: \.0.id) { item in
                            NavigationLink(value: item.0) {
                                VStack(spacing: 8) {
                                    AchievementBadge(achievement: item.0, unlocked: true, size: 64)
                                    Text(item.0.name).font(.caption.weight(.semibold))
                                        .multilineTextAlignment(.center).lineLimit(2).frame(width: 84)
                                    RarityChip(rarity: item.0.rarity)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: Almost there

    @ViewBuilder private var almostThere: some View {
        let near = model.almostThere(limit: 4)
        if !near.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Almost There")
                ForEach(near, id: \.achievement.id) { item in
                    NavigationLink(value: item.achievement) {
                        AchievementProgressCard(achievement: item.achievement, progress: item.progress)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Category section

    private func categorySection(_ category: AchievementCategory) -> some View {
        let items = model.achievementsCatalog.filter { $0.category == category }
            .sorted { lhs, rhs in
                let lp = model.progress(for: lhs.id), rp = model.progress(for: rhs.id)
                if (lp?.isUnlocked ?? false) != (rp?.isUnlocked ?? false) { return (lp?.isUnlocked ?? false) }
                return (lp?.fraction ?? 0) > (rp?.fraction ?? 0)
            }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: category.title,
                          subtitle: "\(items.filter { model.isUnlocked($0.id) }.count)/\(items.count) unlocked")
            let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { a in
                    let unlocked = model.isUnlocked(a.id)
                    let hidden = a.isHiddenUntilClose && !unlocked && (model.progress(for: a.id)?.fraction ?? 0) < 0.5
                    NavigationLink(value: a) {
                        VStack(spacing: 6) {
                            AchievementBadge(achievement: a, unlocked: unlocked, size: 58)
                            Text(hidden ? "???" : a.name).font(.caption2.weight(.semibold))
                                .multilineTextAlignment(.center).lineLimit(2)
                                .frame(height: 30)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Detail for a single achievement: description, requirement, progress, rarity, and the
/// restaurants contributing toward it.
struct AchievementDetailView: View {
    @Environment(AppModel.self) private var model
    let achievement: Achievement
    @State private var showShare = false

    private var progress: AchievementProgress? { model.progress(for: achievement.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AchievementBadge(achievement: achievement, unlocked: progress?.isUnlocked ?? false, size: 110)
                    .padding(.top)
                VStack(spacing: 6) {
                    Text(achievement.name).font(.title.bold())
                    HStack(spacing: 8) {
                        RarityChip(rarity: achievement.rarity)
                        Text(achievement.kind.label.uppercased())
                            .font(.system(size: 9, weight: .heavy)).tracking(0.6).foregroundStyle(.secondary)
                    }
                    Text(achievement.description).font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let p = progress {
                    VStack(spacing: 8) {
                        ProgressView(value: p.fraction).tint(achievement.rarity.tint)
                        Text(p.isUnlocked
                             ? "Unlocked \(p.unlockedDate?.relativeShort ?? "")"
                             : "\(p.current) / \(p.target) · \(p.remaining) to go")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding()
                    .cardSurface()
                }

                contributingRestaurants
                friendsWhoEarned
            }
            .padding()
        }
        .navigationTitle("Achievement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShare = true } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareCardSheet { AchievementShareCard(achievement: achievement) }
        }
    }

    @ViewBuilder private var contributingRestaurants: some View {
        let contributing = model.restaurantsContributing(to: achievement)
        if !contributing.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Counts Toward This").sectionTitleStyle()
                ForEach(contributing.prefix(6)) { r in
                    NavigationLink(value: r) {
                        HStack(spacing: 10) {
                            RestaurantThumb(restaurant: r, size: 40)
                            Text(r.name).font(.subheadline)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardSurface()
        }
    }

    @ViewBuilder private var friendsWhoEarned: some View {
        // Illustrative: friends whose taste suggests they'd have this (mock social proof).
        let friends = model.friends.filter { $0.restaurantsVisited > 120 }.prefix(4)
        if !friends.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Friends With This").sectionTitleStyle()
                HStack(spacing: -8) {
                    ForEach(Array(friends)) { f in
                        FriendAvatar(user: f, size: 40, showRing: true, ringColor: Color(.systemBackground))
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardSurface()
        }
    }
}
