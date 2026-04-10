import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject private var store: StoreService

    @AppStorage(SettingsKey.speed) private var speedRaw: String = BreathingSpeed.standard.rawValue
    @AppStorage(SettingsKey.rounds) private var rounds: Int = 3
    @AppStorage(SettingsKey.breathsBeforeRetention) private var breaths: Int = 35

    @AppStorage(SettingsKey.backgroundMusicEnabled) private var backgroundMusicEnabled: Bool = true
    @AppStorage(SettingsKey.breathingPhaseMusic) private var breathingPhaseMusic: Bool = true
    @AppStorage(SettingsKey.breathingPhaseMusicTrack) private var breathingPhaseMusicTrack: String = "sweet_and_spicy"
    @AppStorage(SettingsKey.retentionPhaseMusic) private var retentionPhaseMusic: Bool = true
    @AppStorage(SettingsKey.retentionPhaseMusicTrack) private var retentionPhaseMusicTrack: String = "sweet_and_spicy"

    @AppStorage(SettingsKey.guidanceEnabled) private var guidanceEnabled: Bool = true
    @AppStorage(SettingsKey.breathingPhaseGuidance) private var breathingPhaseGuidance: Bool = true
    @AppStorage(SettingsKey.breathingPhaseGuidanceStyle) private var breathingPhaseGuidanceStyle: String = "classic"
    @AppStorage(SettingsKey.retentionPhaseGuidance) private var retentionPhaseGuidance: Bool = true
    @AppStorage(SettingsKey.retentionPhaseGuidanceStyle) private var retentionPhaseGuidanceStyle: String = "classic"

    @AppStorage(SettingsKey.breathingSounds) private var breathingSounds: Bool = true
    @AppStorage(SettingsKey.hapticFeedback) private var hapticFeedback: Bool = false
    @AppStorage(SettingsKey.pingAndGong) private var pingAndGong: Bool = true

    @State private var showPaywall = false
    @State private var sessionViewModel: SessionViewModel?

    private var speed: BreathingSpeed {
        BreathingSpeed(rawValue: speedRaw) ?? .standard
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SpeedSelector(
                        selection: Binding(
                            get: { speed },
                            set: { newValue in
                                if newValue.isPremium && !store.isPremium {
                                    showPaywall = true
                                } else {
                                    speedRaw = newValue.rawValue
                                }
                            }
                        )
                    )

                    RoundsSelector(selection: $rounds)
                    BreathsSelector(selection: $breaths)

                    MusicSettingsSection(
                        enabled: $backgroundMusicEnabled,
                        breathingEnabled: $breathingPhaseMusic,
                        breathingTrack: $breathingPhaseMusicTrack,
                        retentionEnabled: $retentionPhaseMusic,
                        retentionTrack: $retentionPhaseMusicTrack
                    )

                    GuidanceSettingsSection(
                        enabled: $guidanceEnabled,
                        breathingEnabled: $breathingPhaseGuidance,
                        breathingStyle: $breathingPhaseGuidanceStyle,
                        retentionEnabled: $retentionPhaseGuidance,
                        retentionStyle: $retentionPhaseGuidanceStyle
                    )

                    ExtraSettingsSection(
                        breathingSounds: $breathingSounds,
                        hapticFeedback: $hapticFeedback,
                        pingAndGong: $pingAndGong
                    )

                    Button(action: startSession) {
                        Text(String(localized: "config.start"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Constants.Palette.primaryTeal)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(String(localized: "config.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: StatsView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(item: $sessionViewModel) { vm in
                SessionView(viewModel: vm)
            }
        }
    }

    private func startSession() {
        let config = SessionConfiguration(
            speed: speed,
            rounds: rounds,
            breathsBeforeRetention: breaths,
            backgroundMusicEnabled: backgroundMusicEnabled,
            breathingPhaseMusic: breathingPhaseMusic,
            breathingPhaseMusicTrack: breathingPhaseMusicTrack,
            retentionPhaseMusic: retentionPhaseMusic,
            retentionPhaseMusicTrack: retentionPhaseMusicTrack,
            guidanceEnabled: guidanceEnabled,
            breathingPhaseGuidance: breathingPhaseGuidance,
            breathingPhaseGuidanceStyle: breathingPhaseGuidanceStyle,
            retentionPhaseGuidance: retentionPhaseGuidance,
            retentionPhaseGuidanceStyle: retentionPhaseGuidanceStyle,
            breathingSounds: breathingSounds,
            hapticFeedback: hapticFeedback,
            pingAndGong: pingAndGong
        )
        sessionViewModel = SessionViewModel(configuration: config)
    }
}

extension SessionViewModel: Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
