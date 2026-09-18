import SwiftUI

/// A short onboarding that bootstraps the taste model: pick cuisines, react to a few
/// restaurants, set what matters, then drop into Discover. It nudges the *seeded*
/// preference vector so recommendations reflect the choices immediately.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var step = 0
    @State private var likedFamilies: Set<String> = []
    @State private var wouldTry: Set<String> = []
    @State private var priorities: Set<QualityTag> = []

    private let sampleFamilies = ["Chinese", "Sichuan", "Japanese", "Sushi", "Korean", "Ramen",
                                  "Italian", "French", "Mexican", "Hot Pot", "Café", "Dessert"]

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: 4)
                .tint(Theme.accent).padding()

            TabView(selection: $step) {
                welcomeStep.tag(0)
                cuisineStep.tag(1)
                tryStep.tag(2)
                priorityStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            controls.padding()
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
    }

    // MARK: Steps

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "fork.knife.circle.fill").font(.system(size: 80)).foregroundStyle(Theme.accent)
            Text("Welcome to Palate").font(.largeTitle.bold())
            Text("Find restaurants you'll actually like — through your own taste and people whose taste you trust.")
                .font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 30)
            Spacer()
        }
    }

    private var cuisineStep: some View {
        VStack(spacing: 16) {
            stepHeader("What do you love?", "Pick a few cuisines to get started.")
            ScrollView {
                FlowLayout(spacing: 10) {
                    ForEach(sampleFamilies, id: \.self) { fam in
                        CuisineChip(text: fam, isSelected: likedFamilies.contains(fam)) {
                            toggle(fam, in: &likedFamilies)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var tryStep: some View {
        VStack(spacing: 16) {
            stepHeader("Would you try this?", "Tap the ones you'd go to.")
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(sampleRestaurants) { r in
                        Button {
                            toggle(r.id, in: &wouldTry)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    RestaurantImage(restaurant: r, height: 100)
                                    if wouldTry.contains(r.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, Theme.accent).padding(6)
                                    }
                                }
                                Text(r.name).font(.caption.weight(.semibold)).lineLimit(1)
                                Text(r.cuisine.label).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }

    private var priorityStep: some View {
        VStack(spacing: 16) {
            stepHeader("What matters most?", "This fine-tunes your recommendations.")
            FlowLayout(spacing: 10) {
                ForEach(QualityTag.allCases) { tag in
                    CuisineChip(text: tag.label, isSelected: priorities.contains(tag)) {
                        toggle(tag, in: &priorities)
                    }
                }
            }
            .padding()
            Spacer()
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
            }
            Spacer()
            Button(step == 3 ? "Start exploring" : "Continue") {
                if step == 3 { finish() } else { withAnimation { step += 1 } }
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
            .disabled(step == 1 && likedFamilies.isEmpty)
        }
    }

    private func stepHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.title.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top)
    }

    /// A handful of visually distinct restaurants across cuisines for the "would you try" step.
    private var sampleRestaurants: [Restaurant] {
        let picks = ["sh-linglong", "se-mingles", "ny-atomix", "sf-benu", "tk-sukiyabashi", "sh-hakkasan"]
        return picks.compactMap { model.restaurant($0) }
    }

    private func toggle<T: Hashable>(_ item: T, in set: inout Set<T>) {
        if set.contains(item) { set.remove(item) } else { set.insert(item); Haptics.tap() }
    }

    // MARK: Finish — seed the taste model from onboarding choices

    private func finish() {
        // Build a target vector from selected cuisine families and priorities, then nudge.
        var target = model.currentUser.preferences
        for fam in likedFamilies {
            for dim in dimensions(forFamily: fam) { target[dim] = min(1, target[dim] + 0.2) }
        }
        target.reinforce(priorities.flatMap { $0.dimensions }, by: 0.15)
        model.currentUser.preferences.nudge(toward: target, rate: 0.5)

        // Saved "would try" become want-to-try.
        for id in wouldTry { model.wantToTryIDs.insert(id) }

        model.onboardingComplete = true
        model.persist()
        Haptics.success()
    }

    private func dimensions(forFamily fam: String) -> [TasteDimension] {
        switch fam {
        case "Chinese": return [.chinese]
        case "Sichuan": return [.sichuan, .spicy]
        case "Japanese", "Sushi": return [.japanese]
        case "Korean": return [.korean]
        case "Ramen": return [.japanese, .casual]
        case "Italian": return [.italian]
        case "French": return [.french, .fineDining]
        case "Mexican": return [.mexican, .streetFood]
        case "Hot Pot": return [.spicy, .casual]
        case "Café": return [.coffee]
        case "Dessert": return [.dessert]
        default: return []
        }
    }
}
