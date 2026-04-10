import Foundation

struct MusicTrack: Identifiable, Hashable {
    let id: String
    let title: String
    let isPremium: Bool
}

enum MusicCatalog {
    static let all: [MusicTrack] = [
        MusicTrack(id: "sweet_and_spicy", title: "Sweet & Spicy", isPremium: false),
        MusicTrack(id: "forest_treasure", title: "Forest Treasure", isPremium: true)
    ]

    static func track(for id: String) -> MusicTrack? {
        all.first { $0.id == id }
    }

    static func displayName(for id: String) -> String {
        track(for: id)?.title ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
