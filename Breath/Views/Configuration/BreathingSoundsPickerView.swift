import SwiftUI

struct BreathingSoundsPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var voice: String
    @Binding var volume: Double

    @State private var tentativeVoice: String
    @State private var previewingVoice: String?

    private let audio: AudioServiceProtocol

    init(voice: Binding<String>, volume: Binding<Double>, audio: AudioServiceProtocol = AudioService.shared) {
        self._voice = voice
        self._volume = volume
        self._tentativeVoice = State(initialValue: voice.wrappedValue)
        self.audio = audio
    }

    private struct VoiceOption: Identifiable, Hashable {
        let id: String
        let title: String
    }

    private var options: [VoiceOption] {
        [
            VoiceOption(id: "male", title: String(localized: "config.extras.voice_male")),
            VoiceOption(id: "female", title: String(localized: "config.extras.voice_female"))
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(options) { option in
                            voiceRow(option)
                        }
                    }
                    .padding()
                }

                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(Constants.Palette.textSecondary)
                        Slider(value: $volume, in: 0...1) { editing in
                            if !editing { audio.setBreathingVolume(Float(volume)) }
                        }
                        .tint(Constants.Palette.primaryTeal)
                        .onChange(of: volume) { _, newValue in
                            audio.setBreathingVolume(Float(newValue))
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
            .navigationTitle(String(localized: "breathing_picker.title"))
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
            .onDisappear {
                previewingVoice = nil
            }
        }
    }

    @ViewBuilder
    private func voiceRow(_ option: VoiceOption) -> some View {
        let isSelected = tentativeVoice == option.id
        let isPlaying = previewingVoice == option.id

        Button {
            tentativeVoice = option.id
            togglePreview(option.id)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Constants.Palette.primaryTeal)

                Text(option.title)
                    .font(.body)
                    .foregroundStyle(Constants.Palette.primaryTeal)

                Spacer()

                if isSelected {
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
        .accessibilityLabel(Text("Preview \(option.title)"))
    }

    private func togglePreview(_ id: String) {
        audio.setBreathingVolume(Float(volume))
        if previewingVoice == id {
            previewingVoice = nil
        } else {
            audio.previewBreathing(voice: id)
            previewingVoice = id
        }
    }

    private func confirm() {
        voice = tentativeVoice
        previewingVoice = nil
        dismiss()
    }
}
