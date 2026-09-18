# Palate

**Find restaurants you'll actually like — through your own taste and people whose taste you trust.**

Palate is a polished SwiftUI prototype for a social restaurant‑discovery network. It answers one question — *"Where should I eat?"* — by combining three reinforcing systems:

**Personal taste** (a learned preference model) · **Social discovery** (friends weighted by taste match) · **Exploration** (rankings, achievements, a food passport).

It is inspired by interaction ideas from apps like Beli but is an original product: its own information architecture, recommendation engine, ranking system, visual identity, and achievement design. No backend, no API keys, no third‑party dependencies — it compiles and runs directly in Xcode against the iOS 18 simulator.

---

## Running it

1. Open `Palate.xcodeproj` in **Xcode 16+** (built and verified on Xcode 27 / iOS 18 SDK, Swift 5 language mode).
2. Select an **iPhone 16/17** simulator.
3. **Run** (⌘R).

The app launches as the seeded user **Terrence**, already established with 24 ranked restaurants across 5 cities, 8 friends, and in‑progress achievements — so Discover is immediately personalized. First‑run **onboarding** is reachable any time via **Profile → ⋯ → Reset demo data**.

State (rankings, saves, friends, unlocked achievements, taste drift) persists locally between launches in a JSON file in the app's Documents directory.

---

## The product loop

```
DISCOVER → VISIT → RANK → LEARN → ACHIEVE → SHARE → FRIENDS DISCOVER → BETTER DATA → BETTER RECOMMENDATIONS
```

Every ranking generates preference data, which sharpens recommendations, which drives more visits. A ready‑made demo:

1. Open **Discover** → a restaurant shows e.g. **77% MATCH** with a personalized reason.
2. Open it → tap **Been** → answer a few **A/B comparisons**.
3. It animates into your **Shanghai ranking**; your taste vector nudges; the feed posts it.
4. The **AchievementEngine** notices — ranking a sushi/Italian spot crosses **Taste Profile Pro (9→10 cuisines)** and the unlock celebration fires.
5. Open a friend → see your **Taste Match** and where you agree/disagree.
6. Open **Eat Together** → pick friends → get a **group match** that balances everyone's satisfaction.
7. Open **Food Passport** → see your geography as collectible stamps.

---

## Architecture

Lightweight MVVM‑ish: an `@Observable` store (`AppModel`) is the single source of truth; views observe it and call intent methods; **all domain logic lives in engines, never in views**.

```
Palate/
├── Models/            Value types: Restaurant, User, TasteVector, Ranking,
│                      Achievement, Social, Challenge, GroupRecommendation, …
├── Engines/           Pure, testable domain logic (no UI):
│   ├── RecommendationEngine    taste + friends + context + popularity + novelty
│   ├── RankingEngine           binary‑search placement + Bradley‑Terry scores
│   ├── AchievementEngine       data‑driven progress from a stats snapshot
│   ├── GroupRecommendationEngine   mean satisfaction − disagreement penalty
│   └── TasteMatch              calibrated cosine similarity between users
├── Services/
│   ├── AppModel(+Derived)      the store: state, intents, derived queries
│   ├── PersistenceService      swappable protocol; local JSON implementation
│   └── MockData/               cities, 43 restaurants, 9 users, achievements,
│                               collections, and the seeded starting world
├── Components/        Reusable UI: RestaurantCard, MatchBadge, FriendAvatar,
│                      Chips/FlowLayout, RankingRow, AchievementBadge,
│                      PassportStamp, ProfileStat, SocialActivityCard, …
├── Views/             One file per surface (Discover, Detail, RankingFlow,
│                      Rankings, Social, Map, EatTogether, Profile,
│                      Achievements, FoodPassport, Onboarding, ShareCards)
└── Utilities/         Theme (design system), Haptics, extensions
```

### Shared taste space
Both restaurants (as **attribute vectors**) and users (as **preference vectors**) are embedded in the same 19‑dimension `TasteVector` (cuisines, style, values, flavor). This makes match %, taste‑match, and group scoring all reduce to vector math over one basis.

### RecommendationEngine
```
Score = 0.45·Taste + 0.25·Friend + 0.20·Context + 0.05·Popularity + 0.05·Novelty
```
- **Taste** — cosine similarity of user prefs to restaurant attributes.
- **Friend** — friends who ranked/saved it, weighted by *their* taste match with you.
- **Context** — compatibility with the current "What are you looking for?" request.
- **Novelty** — rewards unvisited spots and unexplored cuisines.

Every recommendation carries **explainable reasons** ("Matches your love of Sichuan", "Jason, a 96% taste match, ranks it #1 for Sichuan", "12 minutes away"). The blend is mapped into a believable, well‑spread Match %. The engine is a `protocol` (`RecommendationProviding`) so a real ML/remote service can drop in later.

### RankingEngine
Marking **Been** starts a `RankingSession`: ~log₂(n) A/B comparisons via **binary‑search placement**, layered with **Bradley‑Terry** latent‑score updates on the compared restaurants so leaderboards have smooth, comparable strengths. Optional "what made it better?" tags feed the taste model.

### AchievementEngine
Fully **data‑driven**: 40+ achievements are pure declarations (`requirement`, `rarity`, `kind`). The engine computes progress against an `AchievementStats` snapshot built from live data, detects newly‑crossed unlocks, and surfaces them for the celebration overlay. Three collectible kinds — **Badges** (expertise), **Stamps** (places), **Awards** (accomplishments) — across five rarities. No achievement logic lives in views.

### Online taste learning
Ranking a restaurant nudges the user's preference vector toward its attributes and reinforces any tagged dimensions, so Discover measurably shifts as you use the app.

---

## Design

A warm, appetite‑forward identity (saffron‑coral accent) with generous whitespace and SF Symbols throughout. **Match % is deliberately louder than any star rating** — Palate is not "Yelp with badges." Restaurant imagery is rendered procedurally from a deterministic seed (gradient + cuisine glyph), so the UI is beautiful and **fully functional offline** with no broken images and no network dependency. Full **light & dark mode**, tasteful haptics, and share cards (`ImageRenderer`) for rankings, taste profile, achievements, taste match, and the food passport.

---

## Notes for reviewers

- **No dependencies.** Pure SwiftUI + MapKit + native frameworks.
- **Prototype data** — Michelin/landmark/popularity flags are clearly mock.
- Friend profile stats (restaurants/cities/countries) are display seeds; the **current user's** stats and achievement progress are all derived live from actual in‑app data, so they stay internally consistent as you rank.
- A debug‑only launch hook (`PALATE_SCREEN` / `PALATE_TAB` environment variables, read in `RootView`) jumps directly to a screen for screenshots; it has no effect in normal use.
- The seed is tuned so **Taste Profile Pro** sits at 9/10 cuisines — rank any sushi/Japanese/Italian/French/Thai restaurant to trigger a live achievement unlock during a demo.
