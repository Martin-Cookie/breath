import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage(SettingsKey.notificationsEnabled) private var enabled: Bool = false
    @AppStorage(SettingsKey.notificationHour) private var hour: Int = 8
    @AppStorage(SettingsKey.notificationMinute) private var minute: Int = 0

    private struct Preset: Identifiable {
        let id: String
        let label: String
        let icon: String
        let hour: Int
        let minute: Int
    }

    private var presets: [Preset] {
        [
            Preset(id: "morning", label: String(localized: "notifications.preset.morning"),
                   icon: "sunrise.fill", hour: 7, minute: 0),
            Preset(id: "noon", label: String(localized: "notifications.preset.noon"),
                   icon: "sun.max.fill", hour: 12, minute: 0),
            Preset(id: "evening", label: String(localized: "notifications.preset.evening"),
                   icon: "moon.stars.fill", hour: 20, minute: 0)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                Toggle(String(localized: "notifications.daily_reminder"), isOn: $enabled)
                    .tint(Constants.Palette.primaryTeal)
                    .font(.headline)
                    .padding()
                    .background(Constants.Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onChange(of: enabled) { _, newValue in
                        if newValue {
                            Task {
                                let granted = await NotificationService.requestAuthorization()
                                if granted {
                                    NotificationService.scheduleDailyReminder(hour: hour, minute: minute)
                                } else {
                                    await MainActor.run { enabled = false }
                                }
                            }
                        } else {
                            NotificationService.cancelAll()
                        }
                    }

                if enabled {
                    timePickerCard
                    presetsCard
                    previewCard
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "notifications.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Constants.Palette.primaryTeal, Constants.Palette.tealLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "notifications.hero.title"))
                    .font(.headline)
                    .foregroundStyle(Constants.Palette.primaryTeal)
                Text(String(localized: "notifications.hero.subtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var timePickerCard: some View {
        DatePicker(
            String(localized: "notifications.time"),
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
        .tint(Constants.Palette.primaryTeal)
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "notifications.presets"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Constants.Palette.primaryTeal)

            HStack(spacing: 10) {
                ForEach(presets) { preset in
                    presetChip(preset)
                }
            }
        }
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func presetChip(_ preset: Preset) -> some View {
        let isSelected = hour == preset.hour && minute == preset.minute
        return Button(action: {
            hour = preset.hour
            minute = preset.minute
            NotificationService.scheduleDailyReminder(hour: preset.hour, minute: preset.minute)
        }) {
            VStack(spacing: 6) {
                Image(systemName: preset.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.white : Constants.Palette.primaryTeal)
                Text(preset.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Constants.Palette.primaryTeal)
                Text(String(format: "%02d:%02d", preset.hour, preset.minute))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Constants.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Constants.Palette.primaryTeal : Constants.Palette.primaryTeal.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "notifications.preview"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Constants.Palette.primaryTeal)

            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [Constants.Palette.primaryTeal, Constants.Palette.tealLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "wind")
                            .font(.title3)
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(String(localized: "notifications.app_name"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(localized: "notifications.now"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(localized: "notification.reminder"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(String(localized: "notifications.preview.body"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            )
        }
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
