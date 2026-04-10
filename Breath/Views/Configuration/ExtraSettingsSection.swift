import SwiftUI

struct ExtraSettingsSection: View {
    @Binding var breathingSounds: Bool
    @Binding var hapticFeedback: Bool
    @Binding var pingAndGong: Bool

    var body: some View {
        VStack(spacing: 12) {
            Toggle("Breathing sounds", isOn: $breathingSounds)
            Toggle("Haptic feedback", isOn: $hapticFeedback)
            Toggle("Ping and Gong", isOn: $pingAndGong)
        }
        .tint(Constants.Palette.primaryTeal)
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
