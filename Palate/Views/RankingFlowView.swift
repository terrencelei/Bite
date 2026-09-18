import SwiftUI

/// The core ranking interaction: mark "Been" → a few A/B comparisons → the restaurant
/// animates into the city leaderboard → optional "what made it better?" tags.
struct RankingFlowView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant

    @State private var session: RankingSession?
    @State private var phase: Phase = .comparing
    @State private var selectedTags: Set<QualityTag> = []
    @State private var insertedEntry: RankingEntry?

    enum Phase { case comparing, tags, result }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .comparing: comparingView
                case .tags: tagsView
                case .result: resultView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if phase == .comparing { Button("Cancel") { dismiss() } }
                }
            }
        }
        .onAppear { if session == nil { session = model.makeRankingSession(for: restaurant.id) } }
        .interactiveDismissDisabled(phase != .comparing)
    }

    // MARK: Comparing

    @ViewBuilder private var comparingView: some View {
        if let session {
            VStack(spacing: 20) {
                // First-ever ranking: no opponents, skip straight to tags.
                if session.currentOpponentID == nil {
                    Color.clear.onAppear { advanceFromComparisons() }
                }

                VStack(spacing: 6) {
                    Text("Which did you prefer?").font(.title2.bold())
                    Text("Ranking \(restaurant.name)").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.top)

                ProgressView(value: session.progress)
                    .tint(Theme.accent)
                    .padding(.horizontal, 40)

                if let opponentID = session.currentOpponentID, let opponent = model.restaurant(opponentID) {
                    VStack(spacing: 14) {
                        comparisonCard(restaurant, tag: "This one") { choose(preferredNew: true) }
                        Text("VS").font(.caption.weight(.heavy)).foregroundStyle(.secondary)
                        comparisonCard(opponent, tag: nil) { choose(preferredNew: false) }
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
        }
    }

    private func comparisonCard(_ r: Restaurant, tag: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RestaurantImage(restaurant: r, height: 150)
                VStack(alignment: .leading, spacing: 2) {
                    if let tag {
                        Text(tag.uppercased()).font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
                    }
                    Text(r.name).font(.title3.bold()).foregroundStyle(.white)
                    Text("\(r.cuisine.label) · \(r.neighborhood)").font(.caption).foregroundStyle(.white.opacity(0.9))
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }

    private func choose(preferredNew: Bool) {
        Haptics.select()
        session?.choose(preferredNew: preferredNew)
        if session?.isFinished == true {
            advanceFromComparisons()
        }
    }

    private func advanceFromComparisons() {
        withAnimation(.spring) { phase = .tags }
    }

    // MARK: Tags

    private var tagsView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("What made it better?").font(.title2.bold())
                Text("Optional — this sharpens your taste profile.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.top, 30)

            FlowLayout(spacing: 10) {
                ForEach(QualityTag.allCases) { tag in
                    CuisineChip(text: tag.label, isSelected: selectedTags.contains(tag)) {
                        if selectedTags.contains(tag) { selectedTags.remove(tag) }
                        else { selectedTags.insert(tag); Haptics.tap() }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                commit()
            } label: {
                Text("Add to my rankings").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .padding()
        }
    }

    private func commit() {
        guard let session else { return }
        let entry = model.applyRanking(session: session, tags: Array(selectedTags))
        insertedEntry = entry
        withAnimation(.spring) { phase = .result }
    }

    // MARK: Result — animate into leaderboard

    private var resultView: some View {
        let scope = RankingScope(kind: .city(restaurant.cityID), title: "", subtitle: "", symbol: "")
        let entries = model.entries(in: scope)
        let newRank = model.rank(of: restaurant.id, in: scope) ?? 1

        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 44)).foregroundStyle(Theme.accent)
                Text("Added to your ranking").font(.title2.bold())
                Text("Your \(model.city(restaurant.cityID)?.name ?? "") list · now #\(newRank)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(entries.prefix(10).enumerated()), id: \.element.entry.id) { idx, item in
                        RankingRow(position: idx + 1, restaurant: item.restaurant, isNew: item.entry.isNew)
                            .padding(.horizontal)
                            .background(item.entry.isNew ? Theme.accent.opacity(0.08) : .clear)
                        Divider().padding(.leading, 60)
                    }
                }
            }

            Button { dismiss() } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.accent)
            .padding()
        }
        .onAppear { Haptics.success() }
    }
}
