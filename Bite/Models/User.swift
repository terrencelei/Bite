import Foundation

/// A person in the network (the current user or a friend).
/// `preferences` is their location in taste space and drives every recommendation.
struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var handle: String
    /// Emoji/monogram avatar seed — procedural avatars keep the prototype offline-safe.
    var avatarEmoji: String

    var preferences: TasteVector

    /// Cities the user is active in (first is "home").
    var cityIDs: [String]

    /// Short taste descriptors surfaced on the profile ("Adventurous", "Value-conscious").
    var tasteTraits: [String]

    /// Pre-seeded activity totals so friends feel lived-in without simulating full histories.
    var restaurantsVisited: Int
    var citiesCount: Int
    var countriesCount: Int

    var isCurrentUser: Bool = false

    var monogram: String {
        avatarEmoji.isEmpty ? String(name.prefix(1)) : avatarEmoji
    }
}

/// A directed friendship edge from the current user to another user.
struct Friendship: Identifiable, Codable, Hashable {
    let id: String
    let userID: String       // the friend
    let since: Date
}
