import SwiftUI

struct GuidanceSettingsSection: View {
    @Binding var enabled: Bool
    @Binding var breathingEnabled: Bool
    @Binding var breathingStyle: String
    @Binding var retentionEnabled: Bool
    @Binding var retentionStyle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(String(localized: "config.guidance.title"), isOn: $enabled)
                .tint(Constants.Palette.primaryTeal)
                .font(.headline)

            if enabled {
                Toggle(String(localized: "config.guidance.breathing"), isOn: $breathingEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if breathingEnabled {
                    Text(breathingStyle.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(Constants.Palette.textSecondary)
                        .padding(.leading, 16)
                }

                Toggle(String(localized: "config.guidance.retention"), isOn: $retentionEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if retentionEnabled {
                    Text(retentionStyle.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(Constants.Palette.textSecondary)
                        .padding(.leading, 16)
                }
            }
        }
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
