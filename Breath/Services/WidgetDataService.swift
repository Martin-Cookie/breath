import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Zapisuje data do sdílených `UserDefaults` (App Group) pro widget.
enum WidgetDataService {

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Constants.AppGroup.identifier)
    }

    static func update(with sessions: [Session]) {
        guard let defaults = sharedDefaults else { return }
        let info = StreakService.compute(from: sessions)
        defaults.set(info.currentStreak, forKey: SettingsKey.currentStreak)
        defaults.set(info.bestStreak, forKey: SettingsKey.bestStreak)
        if let lastDate = info.lastSessionDate {
            defaults.set(lastDate.timeIntervalSince1970, forKey: SettingsKey.lastSessionDate)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
