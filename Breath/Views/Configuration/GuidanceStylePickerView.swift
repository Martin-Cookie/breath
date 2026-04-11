import SwiftUI

struct GuidanceStylePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreService

    @Binding var selectedStyle: String
    @Binding var volume: Double

    @State private var tentativeStyle: String
    @State private var previewingStyle: String?
    @State private var showPaywall = false

    private let audio: AudioServiceProtocol

    init(selectedStyle: Binding<String>, volume: Binding<Double>, audio: AudioServiceProtocol = AudioService.shared) {
        self._selectedStyle = selectedStyle
        self._volume = volume
        self._tentativeStyle = State(initialValue: selectedStyle.wrappedValue)
        self.audio = audio
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(GuidanceCatalog.all) { style in
                            styleRow(style)
                        }
                    }
                    .padding()
                }

                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(Constants.Palette.textSecondary)
                        Slider(value: $volume, in: 0...1) { editing in
                            if !editing { audio.setGuidanceVolume(Float(volume)) }
                        }
                        .tint(Constants.Palette.primaryTeal)
                        .onChange(of: volume) { _, newValue in
                            audio.setGuidanceVolume(Float(newValue))
                        }
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(Constants.Palette.primaryTeal)
                    }

                    Button(action: confirm) {
                        Text(String(localized: "music_picker.select"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Constants.Palette.primaryTeal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
                .background(Constants.Palette.surface)
            }
            .navigationTitle(String(localized: "guidance_picker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        audio.stopAll()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Constants.Palette.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private func styleRow(_ style: GuidanceStyle) -> some View {
        let isLocked = style.isPremium && !store.isPremium
        let isSelected = tentativeStyle == style.id
        let isPlaying = previewingStyle == style.id

        Button {
            if isLocked {
                showPaywall = true
                return
            }
            tentativeStyle = style.id
            togglePreview(style.id)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(isLocked ? Constants.Palette.textSecondary.opacity(0.5) : Constants.Palette.primaryTeal)

                Text(style.title)
                    .font(.body)
                    .foregroundStyle(isLocked ? Constants.Palette.textSecondary : Constants.Palette.primaryTeal)

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Constants.Palette.textSecondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Constants.Palette.primaryTeal)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Constants.Palette.primaryTeal.opacity(0.08) : Constants.Palette.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Preview \(style.title)"))
    }

    private func togglePreview(_ id: String) {
        audio.setGuidanceVolume(Float(volume))
        if previewingStyle == id {
            audio.stopAll()
            previewingStyle = nil
        } else {
            audio.playGuidance(key: "breathe_in", style: id)
            previewingStyle = id
        }
    }

    private func confirm() {
        selectedStyle = tentativeStyle
        audio.stopAll()
        dismiss()
    }
}
