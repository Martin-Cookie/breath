import Foundation

/// Sdílený snapshot pro widget — kompilovaný do hlavní app i BreathWidget targetu.
/// Serializovaný v App Group UserDefaults pod klíčem `widget.snapshot`.
struct WidgetSnapshot: Codable {
    let currentStreak: Int
    let bestStreak: Int
    let lastSessionDate: Date?
    /// Best retention time za posledních 7 dní (den 0 = nejstarší, den 6 = dnes).
    let recentRetentions: [Double]

    static let empty = WidgetSnapshot(
        currentStreak: 0,
        bestStreak: 0,
        lastSessionDate: nil,
        recentRetentions: []
    )

    static let snapshotKey = "widget.snapshot"
    static let appGroupIdentifier = "group.cz.martinkoci.breath"
}
