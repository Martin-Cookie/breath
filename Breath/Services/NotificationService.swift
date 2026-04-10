import Foundation
import UserNotifications

enum NotificationService {

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private static let dailyReminderID = "daily.reminder"
    private static let streakWarningID = "streak.warning"

    static func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.reminder")
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("NotificationService error: \(error)") }
        }
    }

    /// Naplánuje varování "Neztrácej svůj X-denní streak!" na večer dnešního dne,
    /// pokud uživatel už několik dní cvičí (streakCount ≥ 2) a dnes ještě necvičil.
    static func scheduleStreakWarning(streakCount: Int, lastSessionDate: Date?, calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakWarningID])

        guard streakCount >= 2 else { return }
        guard let lastSessionDate else { return }

        let today = calendar.startOfDay(for: .now)
        let lastDay = calendar.startOfDay(for: lastSessionDate)
        // Pokud už dnes cvičil, warning nepotřebujeme.
        guard lastDay < today else { return }

        // Naplánuj na 20:00 dnes.
        var components = calendar.dateComponents([.year, .month, .day], from: .now)
        components.hour = 20
        components.minute = 0
        guard let fireDate = calendar.date(from: components), fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.reminder")
        content.body = String(format: String(localized: "notification.streak_warning"), streakCount)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: streakWarningID, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("NotificationService streak warning error: \(error)") }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
