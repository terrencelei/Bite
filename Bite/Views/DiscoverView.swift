import SwiftUI

/// The home screen and the strongest surface in the app: contextual chips, an "Almost
/// There" nudge, and a stack of personalized restaurant shelves.
struct DiscoverView: View {
    @Environment(AppModel.self) private var model
    @State private var showContextSheet = false
    @State private var presetOccasion: Occasion?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                feelingChips
                almostThere
                ForEach(model.discoverSections()) { section in
                    shelf(section)
                }
                Color.clear.frame(height: 8)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .biteDestinations()
        .sheet(isPresented: $showContextSheet) {
            ContextualRecommendationView(presetOccasion: presetOccasion)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { presetOccasion = nil; showContextSheet = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you feeling, \(model.currentUser.name)?")
                .font(.title2.bold())
                .padding(.horizontal)

            Button { presetOccasion = nil; showContextSheet = true } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Find the perfect spot…").fontWeight(.medium)
                    Spacer()
                    Image(systemName: "wand.and.stars")
                }
                .foregroundStyle(.secondary)
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.separator.opacity(0.5), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    // MARK: "What are you feeling?" chips

    private var feelingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Occasion.discoverChips) { occ in
                    ContextChip(occasion: occ) {
                        Haptics.select()
                        presetOccasion = occ
                        showContextSheet = true
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: Almost There module

    @ViewBuilder private var almostThere: some View {
        let near = model.almostThere(limit: 5)
        if !near.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Almost There", subtitle: "A little exploration unlocks these")
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(near, id: \.achievement.id) { item in
                            NavigationLink(value: item.achievement) {
                                almostThereCard(item.achievement, item.progress)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func almostThereCard(_ a: Achievement, _ p: AchievementProgress) -> some View {
        HStack(spacing: 12) {
            AchievementBadge(achievement: a, unlocked: false, size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text(a.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                ProgressView(value: p.fraction).tint(a.rarity.tint).frame(width: 130)
                Text("\(p.remaining) to go").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 240)
        .cardSurface()
    }

    // MARK: Restaurant shelf

    private func shelf(_ section: AppModel.DiscoverSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: section.title, subtitle: section.subtitle).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(section.recommendations) { rec in
                        if let r = model.restaurant(rec.restaurantID) {
                            NavigationLink(value: r) {
                                RestaurantCard(restaurant: r, recommendation: rec)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
