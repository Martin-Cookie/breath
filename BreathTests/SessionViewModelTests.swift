import XCTest
@testable import Breath

@MainActor
final class SessionViewModelTests: XCTestCase {

    private var audio: MockAudioService!
    private var haptic: MockHapticService!

    override func setUp() async throws {
        audio = MockAudioService()
        haptic = MockHapticService()
    }

    /// Rychlá konfigurace pro testy — fast rychlost, 2 nádechy, 1 kolo.
    private func fastConfig(rounds: Int = 1, breaths: Int = 2) -> SessionConfiguration {
        SessionConfiguration(
            speed: .fast,
            rounds: rounds,
            breathsBeforeRetention: breaths,
            backgroundMusicEnabled: false,
            breathingPhaseMusic: false,
            breathingPhaseMusicTrack: "sweet_and_spicy",
            retentionPhaseMusic: false,
            retentionPhaseMusicTrack: "sweet_and_spicy",
            musicVolume: 0.5,
            guidanceEnabled: false,
            breathingPhaseGuidance: false,
            breathingPhaseGuidanceStyle: "classic",
            retentionPhaseGuidance: false,
            retentionPhaseGuidanceStyle: "classic",
            guidanceVolume: 1.0,
            retentionAnnounceInterval: 0,
            breathingSounds: true,
            breathingSoundsVoice: "male",
            breathingSoundsVolume: 1.0,
            hapticFeedback: true,
            pingAndGong: true
        )
    }

    private func makeVM(config: SessionConfiguration? = nil) -> SessionViewModel {
        SessionViewModel(
            configuration: config ?? fastConfig(),
            audio: audio,
            haptic: haptic
        )
    }

    // MARK: - Initial state

    func testInitialStateIsIdle() {
        let vm = makeVM()
        XCTAssertEqual(vm.phase, .idle)
        XCTAssertEqual(vm.currentRound, 1)
        XCTAssertTrue(vm.roundResults.isEmpty)
    }

    // MARK: - Start

    func testStartTransitionsToBreathingAndSetsBreathCount() {
        let vm = makeVM(config: fastConfig(breaths: 5))
        vm.start()
        XCTAssertEqual(vm.phase, .breathing)
        XCTAssertEqual(vm.remainingBreaths, 5)
        XCTAssertNotNil(vm.sessionStart)
    }

    func testStartIsIdempotentWhenNotIdle() {
        let vm = makeVM()
        vm.start()
        let firstStart = vm.sessionStart
        vm.start()
        XCTAssertEqual(vm.sessionStart, firstStart)
    }

    // MARK: - Breathing loop

    func testBreathingLoopDecrementsAndTransitionsToRetention() async throws {
        let vm = makeVM(config: fastConfig(breaths: 2))
        vm.start()

        // Fast = 1.0s inhale + 1.5s exhale = 2.5s per breath. 2 breaths = 5s. Wait 6s.
        try await Task.sleep(nanoseconds: 6_000_000_000)

        XCTAssertEqual(vm.phase, .retention)
        XCTAssertEqual(vm.remainingBreaths, 0)
    }

    func testBreathingSoundsArePlayedWhenEnabled() async throws {
        // breaths: 6 so the first breath is NOT in the warning window (remainingBreaths <= 5).
        let vm = makeVM(config: fastConfig(breaths: 6))
        vm.start()

        // Wait enough for the first non-warning inhale (~immediate) + exhale (~2.5s).
        try await Task.sleep(nanoseconds: 3_000_000_000)

        XCTAssertTrue(audio.calls.contains(.playBreathingIn("male")))
        XCTAssertTrue(audio.calls.contains(.playBreathingOut("male")))

        vm.cancel()
    }

    func testHapticIsFiredOnInhaleWhenEnabled() async throws {
        let vm = makeVM(config: fastConfig(breaths: 1))
        vm.start()

        try await Task.sleep(nanoseconds: 3_000_000_000)

        XCTAssertFalse(haptic.impacts.isEmpty)
    }

    // MARK: - Retention → recovery → round result

    func testTapToBreathTransitionsToRecoveryThenRoundResult() async throws {
        let vm = makeVM(config: fastConfig(rounds: 1, breaths: 1))
        vm.start()

        // Čekání do retention fáze.
        try await waitUntil(timeout: 5) { vm.phase == .retention }

        // Retention běží, ukončíme tapem.
        try await Task.sleep(nanoseconds: 500_000_000)
        vm.tapToBreathe()

        // Čekání na recovery_hold (15s) a následně round_result nebo completed.
        try await waitUntil(timeout: 20) {
            vm.phase == .roundResult || vm.phase == .completed
        }

        XCTAssertEqual(vm.roundResults.count, 1)
        XCTAssertGreaterThan(vm.roundResults[0].retentionTime, 0)
    }

    // MARK: - Retention announce ticker

    func testRetentionAnnouncesAtInterval() async throws {
        let base = fastConfig(breaths: 6)
        let config = SessionConfiguration(
            speed: base.speed,
            rounds: base.rounds,
            breathsBeforeRetention: base.breathsBeforeRetention,
            backgroundMusicEnabled: base.backgroundMusicEnabled,
            breathingPhaseMusic: base.breathingPhaseMusic,
            breathingPhaseMusicTrack: base.breathingPhaseMusicTrack,
            retentionPhaseMusic: base.retentionPhaseMusic,
            retentionPhaseMusicTrack: base.retentionPhaseMusicTrack,
            musicVolume: base.musicVolume,
            guidanceEnabled: base.guidanceEnabled,
            breathingPhaseGuidance: base.breathingPhaseGuidance,
            breathingPhaseGuidanceStyle: base.breathingPhaseGuidanceStyle,
            retentionPhaseGuidance: base.retentionPhaseGuidance,
            retentionPhaseGuidanceStyle: base.retentionPhaseGuidanceStyle,
            guidanceVolume: base.guidanceVolume,
            retentionAnnounceInterval: 1,
            breathingSounds: false,
            breathingSoundsVoice: base.breathingSoundsVoice,
            breathingSoundsVolume: base.breathingSoundsVolume,
            hapticFeedback: false,
            pingAndGong: false
        )
        let vm = makeVM(config: config)
        vm.start()

        try await waitUntil(timeout: 20) { vm.phase == .retention }
        // Wait ~2.5 s in retention so the ticker fires at t=1s and t=2s.
        try await Task.sleep(nanoseconds: 2_500_000_000)
        vm.cancel()

        XCTAssertTrue(audio.calls.contains(.speakRetentionTime(1)))
    }

    func testVolumesAreAppliedOnBreathingStart() {
        let base = fastConfig()
        let config = SessionConfiguration(
            speed: base.speed,
            rounds: base.rounds,
            breathsBeforeRetention: base.breathsBeforeRetention,
            backgroundMusicEnabled: base.backgroundMusicEnabled,
            breathingPhaseMusic: base.breathingPhaseMusic,
            breathingPhaseMusicTrack: base.breathingPhaseMusicTrack,
            retentionPhaseMusic: base.retentionPhaseMusic,
            retentionPhaseMusicTrack: base.retentionPhaseMusicTrack,
            musicVolume: 0.5,
            guidanceEnabled: base.guidanceEnabled,
            breathingPhaseGuidance: base.breathingPhaseGuidance,
            breathingPhaseGuidanceStyle: base.breathingPhaseGuidanceStyle,
            retentionPhaseGuidance: base.retentionPhaseGuidance,
            retentionPhaseGuidanceStyle: base.retentionPhaseGuidanceStyle,
            guidanceVolume: 0.7,
            retentionAnnounceInterval: 0,
            breathingSounds: base.breathingSounds,
            breathingSoundsVoice: base.breathingSoundsVoice,
            breathingSoundsVolume: 0.3,
            hapticFeedback: base.hapticFeedback,
            pingAndGong: base.pingAndGong
        )
        let vm = makeVM(config: config)
        vm.start()

        XCTAssertTrue(audio.calls.contains(.setMusicVolume(0.5)))
        XCTAssertTrue(audio.calls.contains(.setBreathingVolume(0.3)))
        XCTAssertTrue(audio.calls.contains(.setGuidanceVolume(0.7)))
        vm.cancel()
    }

    // MARK: - Cancel

    func testCancelStopsAllTasks() {
        let vm = makeVM()
        vm.start()
        vm.cancel()
        XCTAssertEqual(vm.phase, .cancelled)
        XCTAssertTrue(audio.calls.contains(.stopAll))
    }

    // MARK: - Helpers

    private func waitUntil(
        timeout: TimeInterval,
        condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date.now.addingTimeInterval(timeout)
        while Date.now < deadline {
            if condition() { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTFail("waitUntil timed out after \(timeout)s")
    }
}
