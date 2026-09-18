import SwiftUI

/// The "Eat Together" signature feature: pick friends, set constraints, and get a group
/// recommendation that maximizes predicted satisfaction while penalizing disagreement.
struct EatTogetherView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedIDs: Set<String> = []
    @State private var cityID = "shanghai"
    @State private var maxPrice: PriceLevel = .upscale
    @State private var occasion: Occasion?
    @State private var results: [GroupPick] = []
    @State private var didRun = false

    private var selected: Set<String> { selectedIDs }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                intro
                friendPicker
                settings
                runButton
                if didRun { resultsSection }
            }
            .padding()
        }
        .navigationTitle("Eat Together")
        .navigationBarTitleDisplayMode(.inline)
        .biteDestinations()
    }

    private var intro: some View {
        Text("Pick your crew and we'll find a spot everyone will love — balancing what each person likes against how much they'd disagree.")
            .font(.subheadline).foregroundStyle(.secondary)
    }

    // MARK: Friend picker

    private var friendPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHO'S COMING").font(.caption.weight(.bold)).tracking(0.5).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // Current user is always included.
                    memberChip(model.currentUser, locked: true, isOn: true)
                    ForEach(model.friends) { friend in
                        memberChip(friend, locked: false, isOn: selected.contains(friend.id))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func memberChip(_ user: User, locked: Bool, isOn: Bool) -> some View {
        Button {
            guard !locked else { return }
            if selected.contains(user.id) { selectedIDs.remove(user.id) } else { selectedIDs.insert(user.id); Haptics.tap() }
        } label: {
            VStack(spacing: 6) {
                FriendAvatar(user: user, size: 58, showRing: isOn, ringColor: Theme.accent)
                    .overlay(alignment: .bottomTrailing) {
                        if isOn {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent).background(Circle().fill(.background))
                        }
                    }
                Text(user.name).font(.caption).lineLimit(1)
            }
            .opacity(locked || isOn ? 1 : 0.6)
            .frame(width: 68)
        }
        .buttonStyle(.plain)
    }

    // MARK: Settings

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("City").font(.subheadline.weight(.medium))
                Spacer()
                Picker("City", selection: $cityID) {
                    ForEach(model.cities) { Text($0.name).tag($0.id) }
                }.pickerStyle(.menu).tint(Theme.accent)
            }
            HStack {
                Text("Max budget").font(.subheadline.weight(.medium))
                Spacer()
                Picker("Budget", selection: $maxPrice) {
                    ForEach(PriceLevel.allCases, id: \.self) { p in
                        Text(p.display(currency: model.currency(for: cityID))).tag(p)
                    }
                }.pickerStyle(.menu).tint(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Occasion").font(.subheadline.weight(.medium))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Occasion.discoverChips) { occ in
                            CuisineChip(text: occ.label, symbol: occ.symbol, isSelected: occasion == occ) {
                                occasion = occasion == occ ? nil : occ
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .cardSurface()
    }

    private var runButton: some View {
        Button {
            run()
        } label: {
            Label("Find our spot", systemImage: "sparkle.magnifyingglass").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).controlSize(.large).tint(Theme.accent)
    }

    private func run() {
        Haptics.tap()
        let members = [model.currentUser.id] + Array(selected)
        let request = GroupRequest(memberIDs: members, cityID: cityID, maxPrice: maxPrice,
                                   occasion: occasion, cuisineFamily: nil)
        results = model.groupRecommendations(request: request)
        model.recordGroupRecommendation()   // counts toward Matchmaker + Friends Dinner
        withAnimation(.spring) { didRun = true }
    }

    // MARK: Results

    @ViewBuilder private var resultsSection: some View {
        if results.isEmpty {
            ContentUnavailableView("No group match", systemImage: "person.2.slash",
                                   description: Text("Try a higher budget or a different city."))
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("Best for the group").sectionTitleStyle()
                ForEach(results) { pick in
                    if let r = model.restaurant(pick.restaurantID) {
                        NavigationLink(value: r) { groupPickCard(r, pick) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func groupPickCard(_ r: Restaurant, _ pick: GroupPick) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RestaurantImage(restaurant: r, height: 140)
                HStack(spacing: 4) {
                    Text(pick.groupScore.asPercent).font(.subheadline.bold())
                    Text("GROUP MATCH").font(.system(size: 9, weight: .heavy)).tracking(0.5)
                }
                .foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 6)
                .background(Theme.matchColor(pick.groupScore), in: Capsule()).padding(10)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(r.name).font(.headline)
                Text("\(r.cuisine.label) · \(r.neighborhood)").font(.subheadline).foregroundStyle(.secondary)

                // Per-member satisfaction bars.
                VStack(spacing: 6) {
                    ForEach(pick.memberMatches) { m in
                        if let u = model.user(m.userID) {
                            HStack(spacing: 8) {
                                Text(u.name).font(.caption).frame(width: 64, alignment: .leading).lineLimit(1)
                                ProgressView(value: m.score).tint(Theme.matchColor(m.score))
                                Text(m.score.asPercent).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                    .frame(width: 38, alignment: .trailing)
                            }
                        }
                    }
                }
                Text(pick.reason).font(.footnote).foregroundStyle(.secondary).padding(.top, 2)
            }
            .padding(14)
        }
        .cardSurface()
    }
}
