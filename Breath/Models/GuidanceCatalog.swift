import Foundation

struct GuidanceStyle: Identifiable, Hashable {
    let id: String
    let title: String
    let isPremium: Bool
}

enum GuidanceCatalog {
    static let all: [GuidanceStyle] = [
        GuidanceStyle(id: "classic", title: "Classic", isPremium: false),
        GuidanceStyle(id: "calm", title: "Calm", isPremium: true),
        GuidanceStyle(id: "energetic", title: "Energetic", isPremium: true)
    ]

    static func style(for id: String) -> GuidanceStyle? {
        all.first { $0.id == id }
    }

    static func displayName(for id: String) -> String {
        style(for: id)?.title ?? id.capitalized
    }
}
