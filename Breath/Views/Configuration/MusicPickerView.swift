import SwiftUI

struct MusicPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreService

    @Binding var selectedTrack: String
    @Binding var volume: Double

    @State private var tentativeTrack: String
    @State private var previewingTrack: String?
    @State private var showPaywall = false

    init(selectedTrack: Binding<String>, volume: Binding<Double>) {
        self._selectedTrack = selectedTrack
        self._volume = volume
        self._tentativeTrack = State(initialValue: selectedTrack.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(MusicCatalog.all) { track in
                            trackRow(track)
                        }
                    }
                    .padding()
                }

                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(Constants.Palette.textSecondary)
                        Slider(value: $volume, in: 0...1) { editing in
                            if !editing { AudioService.shared.setMusicVolume(Float(volume)) }
                        }
                        .tint(Constants.Palette.primaryTeal)
                        .onChange(of: volume) { _, newValue in
                            AudioService.shared.setMusicVolume(Float(newValue))
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
            .navigationTitle(String(localized: "music_picker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AudioService.shared.stopPreview()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Constants.Palette.textSecondary)
                    }
                }
            }
            .onDisappear {
                AudioService.shared.stopPreview()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private func trackRow(_ track: MusicTrack) -> some View {
        let isLocked = track.isPremium && !store.isPremium
        let isSelected = tentativeTrack == track.id
        let isPlaying = previewingTrack == track.id

        Button {
            if isLocked {
                showPaywall = true
                return
            }
            tentativeTrack = track.id
            togglePreview(track.id)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(isLocked ? Constants.Palette.textSecondary.opacity(0.5) : Constants.Palette.primaryTeal)

                Text(track.title)
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
    }

    private func togglePreview(_ trackId: String) {
        if previewingTrack == trackId {
            AudioService.shared.stopPreview()
            previewingTrack = nil
        } else {
            AudioService.shared.previewMusic(track: trackId)
            previewingTrack = trackId
        }
    }

    private func confirm() {
        selectedTrack = tentativeTrack
        AudioService.shared.stopPreview()
        dismiss()
    }
}
