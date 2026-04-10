import SwiftUI

struct ExtraSettingsSection: View {
    @Binding var breathingSounds: Bool
    @Binding var breathingSoundsVoice: String
    @Binding var breathingSoundsVolume: Double
    @Binding var hapticFeedback: Bool
    @Binding var pingAndGong: Bool

    @State private var showBreathingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(String(localized: "config.extras.breathing_sounds"), isOn: $breathingSounds)

            if breathingSounds {
                Button {
                    showBreathingPicker = true
                } label: {
                    HStack {
                        Text(voiceLabel)
                            .font(.subheadline)
                            .foregroundStyle(Constants.Palette.primaryTeal)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Constants.Palette.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Constants.Palette.primaryTeal.opacity(0.08))
                    )
                    .padding(.leading, 16)
                }
                .buttonStyle(.plain)
            }

            Toggle(String(localized: "config.extras.haptic"), isOn: $hapticFeedback)
            Toggle(String(localized: "config.extras.ping_gong"), isOn: $pingAndGong)
        }
        .tint(Constants.Palette.primaryTeal)
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showBreathingPicker) {
            BreathingSoundsPickerView(
                voice: $breathingSoundsVoice,
                volume: $breathingSoundsVolume
            )
        }
    }

    private var voiceLabel: String {
        breathingSoundsVoice == "female"
            ? String(localized: "config.extras.voice_female")
            : String(localized: "config.extras.voice_male")
    }
}
