import SwiftUI

struct MusicSettingsSection: View {
    @Binding var enabled: Bool
    @Binding var breathingEnabled: Bool
    @Binding var breathingTrack: String
    @Binding var retentionEnabled: Bool
    @Binding var retentionTrack: String
    @Binding var volume: Double

    @State private var editingPhase: Phase?

    private enum Phase: Identifiable {
        case breathing, retention
        var id: Int { self == .breathing ? 0 : 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(String(localized: "config.music.title"), isOn: $enabled)
                .tint(Constants.Palette.primaryTeal)
                .font(.headline)

            if enabled {
                Toggle(String(localized: "config.music.breathing"), isOn: $breathingEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if breathingEnabled {
                    trackRow(MusicCatalog.displayName(for: breathingTrack)) {
                        editingPhase = .breathing
                    }
                }

                Toggle(String(localized: "config.music.retention"), isOn: $retentionEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if retentionEnabled {
                    trackRow(MusicCatalog.displayName(for: retentionTrack)) {
                        editingPhase = .retention
                    }
                }
            }
        }
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $editingPhase) { phase in
            switch phase {
            case .breathing:
                MusicPickerView(selectedTrack: $breathingTrack, volume: $volume)
            case .retention:
                MusicPickerView(selectedTrack: $retentionTrack, volume: $volume)
            }
        }
    }

    private func trackRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
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
}
