import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "fork.knife.circle.fill").font(.system(size: 72)).foregroundStyle(Theme.accent)
                Text("Make every bite yours.").font(.largeTitle.bold())
                Text("Find real restaurants near you, save your next stop, and build a personal ranking as you explore.")
                    .font(.title3).foregroundStyle(.secondary)
                TextField("Your name (optional)", text: $name)
                    .textContentType(.givenName).textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("onboardingName")
                Label("Choose your location when you’re ready, or search any city.", systemImage: "location")
                Label("Your saved places and rankings stay on this device.", systemImage: "lock")
                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    model.currentUser.name = trimmed.isEmpty ? "You" : String(trimmed.prefix(60))
                    model.onboardingComplete = true
                    model.persist()
                } label: { Text("Start exploring").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).controlSize(.large).tint(Theme.accent)
                    .accessibilityIdentifier("startExploring")
            }.padding(28)
        }
    }
}
