import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject private var store: StoreService
    @StateObject private var vm = ConfigurationViewModel()

    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var sessionViewModel: SessionViewModel?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
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
                    }
                    .padding()
                    // Prostor pro sticky Start button, aby nepřekrýval obsah.
                    .padding(.bottom, 96)
                }

                // Sticky bottom Start button — vždy viditelný.
                Button(action: startSession) {
                    Text(String(localized: "config.start"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Constants.Palette.primaryTeal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Constants.Palette.primaryTeal.opacity(0.25), radius: 12, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.95), .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            .navigationTitle(String(localized: "config.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: StatsView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
