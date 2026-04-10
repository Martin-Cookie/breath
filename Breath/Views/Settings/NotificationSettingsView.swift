import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage(SettingsKey.notificationsEnabled) private var enabled: Bool = false
    @AppStorage(SettingsKey.notificationHour) private var hour: Int = 8
    @AppStorage(SettingsKey.notificationMinute) private var minute: Int = 0

    var body: some View {
        Form {
            Toggle("Daily reminder", isOn: $enabled)
                .tint(Constants.Palette.primaryTeal)
                .onChange(of: enabled) { _, newValue in
                    if newValue {
                        Task {
                            let granted = await NotificationService.requestAuthorization()
                            if granted {
                                NotificationService.scheduleDailyReminder(hour: hour, minute: minute)
                            } else {
                                enabled = false
                            }
                        }
                    } else {
                        NotificationService.cancelAll()
                    }
                }

            if enabled {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = hour
                            components.minute = minute
                            return Calendar.current.date(from: components) ?? .now
                        },
                        set: { newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            hour = components.hour ?? 8
                            minute = components.minute ?? 0
                            NotificationService.scheduleDailyReminder(hour: hour, minute: minute)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
        .navigationTitle("Notifications")
    }
}
