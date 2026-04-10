import Foundation
import Combine
import SwiftUI

@MainActor
final class SessionViewModel: ObservableObject {

    // MARK: - State machine

    enum Phase: Equatable {
        case idle
        case breathing
        case retention
        case recoveryIn
        case recoveryHold
        case roundResult
        case completed
        case cancelled
    }

    enum BreathStep: Equatable {
        case inhale
        case exhale
    }

    // MARK: - Published state

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var remainingBreaths: Int = 0
    @Published private(set) var breathStep: BreathStep = .inhale
    @Published private(set) var retentionElapsed: TimeInterval = 0
    @Published private(set) var recoveryRemaining: TimeInterval = Constants.Session.recoveryHoldDuration
    @Published private(set) var roundResults: [RoundResult] = []
    @Published private(set) var sessionStart: Date?
    @Published private(set) var sessionDuration: TimeInterval = 0

    // MARK: - Dependencies

    let configuration: SessionConfiguration
    private let audio: AudioServiceProtocol
    private let haptic: HapticServiceProtocol

    // MARK: - Internal

    private var breathTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?
    private var retentionStart: Date?

    init(
        configuration: SessionConfiguration,
        audio: AudioServiceProtocol = AudioService.shared,
        haptic: HapticServiceProtocol = HapticService.shared
    ) {
        self.configuration = configuration
        self.audio = audio
        self.haptic = haptic
    }

    // MARK: - Lifecycle

    func start() {
        guard phase == .idle else { return }
        sessionStart = .now
        currentRound = 1
        roundResults = []
        beginBreathingPhase()
    }

    func cancel() {
        stopAllTasks()
        audio.stopAll()
        phase = .cancelled
    }

    /// Uživatel tapnul během retention fáze.
    func tapToBreathe() {
        guard phase == .retention else { return }
        finishRetention()
    }

    /// Uživatel tapnul na mezivýsledek kola.
    func advanceFromRoundResult() {
        guard phase == .roundResult else { return }
        proceedAfterRound()
    }

    // MARK: - Phase: breathing

    private func beginBreathingPhase() {
        phase = .breathing
        remainingBreaths = configuration.breathsBeforeRetention
        breathStep = .inhale

        audio.setMusicVolume(Float(configuration.musicVolume))
        audio.setBreathingVolume(Float(configuration.breathingSoundsVolume))
        audio.setGuidanceVolume(Float(configuration.guidanceVolume))
        if configuration.backgroundMusicEnabled, configuration.breathingPhaseMusic {
            audio.playMusic(track: configuration.breathingPhaseMusicTrack)
        }
        if configuration.guidanceEnabled, configuration.breathingPhaseGuidance {
            audio.playGuidance(key: "breathe_in", style: configuration.breathingPhaseGuidanceStyle)
        }

        breathTask = Task { [weak self] in
            await self?.runBreathingLoop()
        }
    }

    private func runBreathingLoop() async {
        let speed = configuration.speed
        while remainingBreaths > 0, !Task.isCancelled, phase == .breathing {
            let isWarning = remainingBreaths <= 5

            breathStep = .inhale
            if configuration.breathingSounds {
                if isWarning {
                    audio.playWarning()
                } else {
                    audio.playBreathingIn(voice: configuration.breathingSoundsVoice)
                }
            }
            if configuration.hapticFeedback { haptic.impact(isWarning ? .medium : .soft) }
            await sleep(seconds: speed.inhaleDuration)
            guard !Task.isCancelled, phase == .breathing else { return }

            breathStep = .exhale
            if configuration.breathingSounds { audio.playBreathingOut(voice: configuration.breathingSoundsVoice) }
            await sleep(seconds: speed.exhaleDuration)
            guard !Task.isCancelled, phase == .breathing else { return }

            remainingBreaths -= 1
        }
        guard !Task.isCancelled, phase == .breathing else { return }

        if configuration.guidanceEnabled, configuration.breathingPhaseGuidance {
            audio.playGuidance(key: "let_go", style: configuration.breathingPhaseGuidanceStyle)
        }
        beginRetentionPhase()
    }

    // MARK: - Phase: retention

    private func beginRetentionPhase() {
        phase = .retention
        retentionElapsed = 0
        retentionStart = .now
        audio.stopMusic()
        if configuration.backgroundMusicEnabled, configuration.retentionPhaseMusic {
            audio.playMusic(track: configuration.retentionPhaseMusicTrack)
        }
        if configuration.guidanceEnabled, configuration.retentionPhaseGuidance {
            audio.playGuidance(key: "hold", style: configuration.retentionPhaseGuidanceStyle)
        }

        tickerTask = Task { [weak self] in
            await self?.runRetentionTicker()
        }
    }

    private func runRetentionTicker() async {
        let interval = configuration.retentionAnnounceInterval
        var lastAnnouncedTick = 0
        while !Task.isCancelled, phase == .retention {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let start = retentionStart {
                retentionElapsed = Date.now.timeIntervalSince(start)
                if interval > 0 {
                    let tick = Int(retentionElapsed) / interval
                    if tick > lastAnnouncedTick {
                        lastAnnouncedTick = tick
                        audio.speakRetentionTime(seconds: tick * interval)
                    }
                }
            }
        }
    }

    private func finishRetention() {
        tickerTask?.cancel()
        let retention = retentionElapsed
        if configuration.pingAndGong { audio.playPing() }
        audio.stopMusic()

        phase = .recoveryIn
        if configuration.guidanceEnabled, configuration.retentionPhaseGuidance {
            audio.playGuidance(key: "recovery", style: configuration.retentionPhaseGuidanceStyle)
        }

        Task { [weak self] in
            guard let self else { return }
            await self.sleep(seconds: 1.0)
            guard !Task.isCancelled, self.phase == .recoveryIn else { return }
            self.beginRecoveryHold(retentionTime: retention)
        }
    }

    // MARK: - Phase: recovery

    private func beginRecoveryHold(retentionTime: TimeInterval) {
        phase = .recoveryHold
        recoveryRemaining = Constants.Session.recoveryHoldDuration
        let startedAt = Date.now

        tickerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.phase == .recoveryHold {
                try? await Task.sleep(nanoseconds: 100_000_000)
                let elapsed = Date.now.timeIntervalSince(startedAt)
                let remaining = max(0, Constants.Session.recoveryHoldDuration - elapsed)
                self.recoveryRemaining = remaining
                if remaining <= 0 {
                    self.finishRecovery(retentionTime: retentionTime, recoveryHold: Constants.Session.recoveryHoldDuration)
                    return
                }
            }
        }
    }

    private func finishRecovery(retentionTime: TimeInterval, recoveryHold: TimeInterval) {
        tickerTask?.cancel()
        if configuration.pingAndGong { audio.playGong() }

        let result = RoundResult(
            roundNumber: currentRound,
            retentionTime: retentionTime,
            recoveryHoldTime: recoveryHold
        )
        roundResults.append(result)
        phase = .roundResult

        Task { [weak self] in
            guard let self else { return }
            await self.sleep(seconds: Constants.Session.roundResultAutoAdvance)
            guard !Task.isCancelled, self.phase == .roundResult else { return }
            self.proceedAfterRound()
        }
    }

    // MARK: - Round transition

    private func proceedAfterRound() {
        if currentRound < configuration.rounds {
            currentRound += 1
            beginBreathingPhase()
        } else {
            completeSession()
        }
    }

    private func completeSession() {
        stopAllTasks()
        audio.stopAll()
        if let start = sessionStart {
            sessionDuration = Date.now.timeIntervalSince(start)
        }
        phase = .completed
    }

    // MARK: - Helpers

    private func stopAllTasks() {
        breathTask?.cancel()
        tickerTask?.cancel()
        breathTask = nil
        tickerTask = nil
    }

    private func sleep(seconds: TimeInterval) async {
        let nanos = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
