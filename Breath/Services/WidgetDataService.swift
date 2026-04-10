import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Zapisuje data do sdílených `UserDefaults` (App Group) pro widget.
enum WidgetDataService {

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Constants.AppGroup.identifier)
    }

    /// Vytvoří snapshot z čistých sessionů — oddělená logika pro testovatelnost.
    static func makeSnapshot(
        from sessions: [Session],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> WidgetSnapshot {
        let info = StreakService.compute(from: sessions, calendar: calendar, referenceDate: referenceDate)

        // Posledních 7 dní — pro každý den best retention (0 když session chybí).
        var retentions: [Double] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: referenceDate) else {
                retentions.append(0)
                continue
            }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayBest = sessions
                .filter { $0.date >= dayStart && $0.date < dayEnd }
                .map(\.bestRetention)
                .max() ?? 0
            retentions.append(dayBest)
        }

        return WidgetSnapshot(
            currentStreak: info.currentStreak,
            bestStreak: info.bestStreak,
            lastSessionDate: info.lastSessionDate,
            recentRetentions: retentions
        )
    }

    static func update(with sessions: [Session]) {
        guard let defaults = sharedDefaults else { return }
        let snapshot = makeSnapshot(from: sessions)

        // Flat klíče pro rychlý přístup.
        defaults.set(snapshot.currentStreak, forKey: SettingsKey.currentStreak)
        defaults.set(snapshot.bestStreak, forKey: SettingsKey.bestStreak)
        if let lastDate = snapshot.lastSessionDate {
            defaults.set(lastDate.timeIntervalSince1970, forKey: SettingsKey.lastSessionDate)
        }

        // Full snapshot (pro chart data).
        if let encoded = try? JSONEncoder().encode(snapshot) {
            defaults.set(encoded, forKey: WidgetSnapshot.snapshotKey)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func readSnapshot() -> WidgetSnapshot {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: WidgetSnapshot.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}
