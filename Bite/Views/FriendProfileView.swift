import SwiftUI

/// A friend's profile: taste match, stats, featured achievements, their top lists,
/// plus "taste in common" and "where you disagree".
struct FriendProfileView: View {
    @Environment(AppModel.self) private var model
    let user: User
    @State private var showMatchShare = false

    private var match: Double { model.tasteMatch(user) }
    private var isFriend: Bool { model.friendIDs.contains(user.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                headerCard
                addFriendButton
                commonTaste
                disagreements
                topPicks
            }
            .padding()
        }
        .navigationTitle(user.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showMatchShare = true } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showMatchShare) {
            ShareCardSheet {
                TasteMatchShareCard(userName: model.currentUser.name, friendName: user.name,
                                    match: match,
                                    commonCuisines: TasteMatch.commonStrengths(model.currentUser, user).map(\.label))
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            FriendAvatar(user: user, size: 92)
            Text(user.name).font(.title.bold())
            Text(user.handle).font(.subheadline).foregroundStyle(.secondary)

            TasteMatchView(match: match, diameter: 96)

            HStack {
                ProfileStat(value: "\(user.restaurantsVisited)", label: "Restaurants")
                Divider().frame(height: 34)
                ProfileStat(value: "\(user.citiesCount)", label: "Cities")
                Divider().frame(height: 34)
                ProfileStat(value: "\(user.countriesCount)", label: "Countries")
            }

            if !user.tasteTraits.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(user.tasteTraits, id: \.self) { CuisineChip(text: $0, tint: Theme.indigo) }
                }
            }
        }
        .padding()
        .cardSurface()
    }

    @ViewBuilder private var addFriendButton: some View {
        if isFriend {
            Label("Friends", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
        } else {
            Button {
                model.addFriend(user.id)
            } label: {
                Label("Add Friend", systemImage: "person.badge.plus").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
        }
    }

    private var commonTaste: some View {
        let common = TasteMatch.commonStrengths(model.currentUser, user)
        return Group {
            if !common.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Taste in Common").sectionTitleStyle()
                    Text("You both love").font(.subheadline).foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(common.prefix(8), id: \.self) { dim in
                            CuisineChip(text: dim.label, isSelected: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardSurface()
            }
        }
    }

    private var disagreements: some View {
        let diffs = TasteMatch.disagreements(model.currentUser, user)
        return Group {
            if !diffs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Where You Disagree").sectionTitleStyle()
                    ForEach(diffs.prefix(3), id: \.dimension) { diff in
                        HStack {
                            Text(diff.dimension.label).font(.subheadline)
                            Spacer()
                            Text("\(diff.higher) leans in").font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardSurface()
            }
        }
    }

    private var topPicks: some View {
        let picks = (SeedData.friendTopPicks[user.id] ?? []).compactMap { model.restaurant($0) }
        return Group {
            if !picks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(user.name)'s Top Picks").sectionTitleStyle()
                    ForEach(Array(picks.prefix(6).enumerated()), id: \.element.id) { idx, r in
                        NavigationLink(value: r) {
                            RankingRow(position: idx + 1, restaurant: r)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 54)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardSurface()
            }
        }
    }
}
