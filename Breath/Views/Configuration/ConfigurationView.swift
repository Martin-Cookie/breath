import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject private var store: StoreService
    @StateObject private var vm = ConfigurationViewModel()

    @State private var showPaywall = false
    @State private var sessionViewModel: SessionViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SpeedSelector(
                        selection: Binding(
                            get: { vm.speed },
                            set: { newValue in
                                if !vm.setSpeed(newValue, isPremium: store.isPremium) {
                                    showPaywall = true
                                }
                            }
                        )
                    )

                    RoundsSelector(selection: $vm.rounds)
                    BreathsSelector(selection: $vm.breathsBeforeRetention)

                    MusicSettingsSection(
                        enabled: $vm.backgroundMusicEnabled,
                        breathingEnabled: $vm.breathingPhaseMusic,
                        breathingTrack: $vm.breathingPhaseMusicTrack,
                        retentionEnabled: $vm.retentionPhaseMusic,
                        retentionTrack: $vm.retentionPhaseMusicTrack
                    )

                    GuidanceSettingsSection(
                        enabled: $vm.guidanceEnabled,
                        breathingEnabled: $vm.breathingPhaseGuidance,
                        breathingStyle: $vm.breathingPhaseGuidanceStyle,
                        retentionEnabled: $vm.retentionPhaseGuidance,
                        retentionStyle: $vm.retentionPhaseGuidanceStyle
                    )

                    ExtraSettingsSection(
                        breathingSounds: $vm.breathingSounds,
                        hapticFeedback: $vm.hapticFeedback,
                        pingAndGong: $vm.pingAndGong
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
            .fullScreenCover(item: $sessionViewModel) { svm in
                SessionView(viewModel: svm)
            }
        }
    }

    private func startSession() {
        sessionViewModel = SessionViewModel(configuration: vm.makeSessionConfiguration())
    }
}

extension SessionViewModel: Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
