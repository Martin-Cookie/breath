import SwiftUI

struct MusicSettingsSection: View {
    @Binding var enabled: Bool
    @Binding var breathingEnabled: Bool
    @Binding var breathingTrack: String
    @Binding var retentionEnabled: Bool
    @Binding var retentionTrack: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Background music", isOn: $enabled)
                .tint(Constants.Palette.primaryTeal)
                .font(.headline)

            if enabled {
                Toggle("Breathing phase music", isOn: $breathingEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if breathingEnabled {
                    Text(breathingTrack.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline)
                        .foregroundStyle(Constants.Palette.textSecondary)
                        .padding(.leading, 16)
                }

                Toggle("Retention phase music", isOn: $retentionEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if retentionEnabled {
                    Text(retentionTrack.replacingOccurrences(of: "_", with: " ").capitalized)
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
