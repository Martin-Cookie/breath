import SwiftUI

struct GuidanceSettingsSection: View {
    @Binding var enabled: Bool
    @Binding var breathingEnabled: Bool
    @Binding var breathingStyle: String
    @Binding var retentionEnabled: Bool
    @Binding var retentionStyle: String
    @Binding var volume: Double
    @Binding var retentionAnnounceInterval: Int

    @State private var editingPhase: Phase?

    private enum Phase: Identifiable {
        case breathing, retention
        var id: Int { self == .breathing ? 0 : 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(String(localized: "config.guidance.title"), isOn: $enabled)
                .tint(Constants.Palette.primaryTeal)
                .font(.headline)

            if enabled {
                Toggle(String(localized: "config.guidance.breathing"), isOn: $breathingEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if breathingEnabled {
                    styleRow(GuidanceCatalog.displayName(for: breathingStyle)) {
                        editingPhase = .breathing
                    }
                }

                Toggle(String(localized: "config.guidance.retention"), isOn: $retentionEnabled)
                    .tint(Constants.Palette.primaryTeal)
                if retentionEnabled {
                    styleRow(GuidanceCatalog.displayName(for: retentionStyle)) {
                        editingPhase = .retention
                    }
                    retentionAnnounceRow
                }
            }
        }
        .padding()
        .background(Constants.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $editingPhase) { phase in
            switch phase {
            case .breathing:
                GuidanceStylePickerView(selectedStyle: $breathingStyle, volume: $volume)
            case .retention:
                GuidanceStylePickerView(selectedStyle: $retentionStyle, volume: $volume)
            }
        }
    }

    private var retentionAnnounceRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "config.guidance.retention_announce"))
                    .font(.subheadline)
                    .foregroundStyle(Constants.Palette.primaryTeal)
                Spacer()
                Text(intervalLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Constants.Palette.primaryTeal)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(retentionAnnounceInterval) },
                    set: { retentionAnnounceInterval = Int(($0 / 15).rounded()) * 15 }
                ),
                in: 0...60,
                step: 15
            )
            .tint(Constants.Palette.primaryTeal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Constants.Palette.primaryTeal.opacity(0.08))
        )
        .padding(.leading, 16)
    }

    private var intervalLabel: String {
        if retentionAnnounceInterval == 0 {
            return String(localized: "common.off")
        }
        return "\(retentionAnnounceInterval) s"
    }

    private func styleRow(_ title: String, action: @escaping () -> Void) -> some View {
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
