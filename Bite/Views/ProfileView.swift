import SwiftUI

/// The current user's profile: identity, live stats, featured achievements, taste
/// profile, plus entry points to Achievements, Food Passport, and Challenges.
struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @State private var showTasteShare = false
    @State private var showSettings = false
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                statsGrid
                featured
                if model.demoMode { tasteProfile }
                quickLinks
                if !model.challenges.isEmpty { challengesPreview }
                Color.clear.frame(height: 8)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .biteDestinations()
        .navigationDestination(for: ProfileRoute.self) { route in
            switch route {
            case .achievements: AchievementsView()
            case .passport: FoodPassportView()
            case .challenges: ChallengesView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if model.demoMode {
                        Button { showTasteShare = true } label: { Label("Share Taste Profile", systemImage: "square.and.arrow.up") }
                    }
                    Button(role: .destructive) { confirmReset = true } label: { Label("Delete local data", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .confirmationDialog("Delete your saved places and rankings from this device?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Delete local data", role: .destructive) { model.resetToSeed() }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showTasteShare) {
            ShareCardSheet {
                TasteProfileShareCard(userName: model.currentUser.name,
                                      traits: model.currentUser.tasteTraits,
                                      topCuisines: topCuisineLabels)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            FriendAvatar(user: model.currentUser, size: 96)
            Text(model.currentUser.name).font(.title.bold())
            Text(model.currentUser.handle).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: Stats (live-derived)

    private var statsGrid: some View {
        let stats = model.buildAchievementStats()
        let unlocked = model.achievementsCatalog.filter { model.isUnlocked($0.id) }
        let rare = unlocked.filter { $0.rarity >= .rare }.count
        return VStack(spacing: 14) {
            HStack {
                ProfileStat(value: "\(stats.totalRanked)", label: "Ranked")
                ProfileStat(value: "\(stats.cities.count)", label: "Cities")
                ProfileStat(value: "\(stats.countries.count)", label: "Countries")
            }
            HStack {
                ProfileStat(value: "\(stats.cuisineFamilies.count)", label: "Cuisines")
                ProfileStat(value: "\(unlocked.count)", label: "Achievements")
                ProfileStat(value: "\(rare)", label: "Rare+")
            }
        }
        .padding()
        .cardSurface()
    }

    // MARK: Featured achievements

    @ViewBuilder private var featured: some View {
        let ids = model.featuredAchievementIDs
        if !ids.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Featured") { }
                HStack(spacing: 12) {
                    ForEach(ids, id: \.self) { id in
                        if let a = model.achievementByID[id] {
                            NavigationLink(value: a) {
                                VStack(spacing: 6) {
                                    AchievementBadge(achievement: a, unlocked: true, size: 58)
                                    Text(a.name).font(.caption2.weight(.semibold))
                                        .multilineTextAlignment(.center).lineLimit(2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
            .cardSurface()
        }
    }

    // MARK: Taste profile

    private var tasteProfile: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Taste").sectionTitleStyle()

            FlowLayout(spacing: 8) {
                ForEach(model.currentUser.tasteTraits, id: \.self) { CuisineChip(text: $0, isSelected: true) }
            }

            Text("TOP CUISINES").font(.caption.weight(.bold)).tracking(0.5).foregroundStyle(.secondary)
            ForEach(topDimensions, id: \.self) { dim in
                HStack(spacing: 10) {
                    Text(dim.label).font(.subheadline).frame(width: 96, alignment: .leading)
                    ProgressView(value: model.currentUser.preferences[dim]).tint(Theme.accent)
                    Text(model.currentUser.preferences[dim].asPercent)
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 40, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private var topDimensions: [TasteDimension] {
        model.currentUser.preferences.topDimensions(6)
    }

    private var topCuisineLabels: [String] {
        // Prefer cuisine-like dimensions for the share card.
        let cuisineDims: [TasteDimension] = [.japanese, .sichuan, .korean, .chinese, .cantonese, .italian, .french]
        return cuisineDims
            .sorted { model.currentUser.preferences[$0] > model.currentUser.preferences[$1] }
            .prefix(4).map(\.label)
    }

    // MARK: Quick links

    private var quickLinks: some View {
        VStack(spacing: 0) {
            linkRow(.achievements, "Achievements", "rosette", model.achievementsCatalog.filter { model.isUnlocked($0.id) }.count)
            Divider().padding(.leading, 52)
            linkRow(.passport, "Food Passport", "book.pages.fill", model.passport().reduce(0) { $0 + $1.total })
            if !model.challenges.isEmpty {
                Divider().padding(.leading, 52)
                linkRow(.challenges, "Challenges", "flag.checkered", model.challenges.filter { !$0.isComplete }.count)
            }
        }
        .cardSurface()
    }

    private func linkRow(_ route: ProfileRoute, _ title: String, _ symbol: String, _ count: Int) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.headline).foregroundStyle(Theme.accent).frame(width: 28)
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(count)").foregroundStyle(.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Challenges preview

    private var challengesPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Challenges", subtitle: "Optional, low-pressure exploration")
            ForEach(model.challenges.prefix(2)) { challenge in
                ChallengeRow(challenge: challenge)
            }
            NavigationLink(value: ProfileRoute.challenges) { Text("See all challenges").font(.subheadline.weight(.semibold)) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }
}

enum ProfileRoute: Hashable { case achievements, passport, challenges }

/// A single challenge progress row.
struct ChallengeRow: View {
    let challenge: Challenge
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: challenge.symbol)
                .font(.headline).foregroundStyle(challenge.isComplete ? .green : Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(challenge.title).font(.subheadline.weight(.semibold))
                    if let t = challenge.timeframe {
                        Text(t).font(.caption2).foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.groupedBackground, in: Capsule())
                    }
                    Spacer()
                    Text("\(challenge.progress)/\(challenge.target)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Text(challenge.subtitle).font(.caption).foregroundStyle(.secondary)
                ProgressView(value: challenge.fraction).tint(challenge.isComplete ? .green : Theme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Full challenges list.
struct ChallengesView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(model.challenges) { c in
                    ChallengeRow(challenge: c).padding().cardSurface()
                }
            }
            .padding()
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }
}
