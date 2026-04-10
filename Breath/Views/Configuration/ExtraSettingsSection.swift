import SwiftUI

struct ExtraSettingsSection: View {
    @Binding var breathingSounds: Bool
    @Binding var hapticFeedback: Bool
    @Binding var pingAndGong: Bool

    var body: some View {
        VStack(spacing: 12) {
            Toggle(String(localized: "config.extras.breathing_sounds"), isOn: $breathingSounds)
            Toggle(String(localized: "config.extras.haptic"), isOn: $hapticFeedback)
            Toggle(String(localized: "config.extras.ping_gong"), isOn: $pingAndGong)
        }
        .tint(Constants.Palette.primaryTeal)
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
