import Foundation
import SwiftUI
import Combine

/// Držitel stavu konfigurační obrazovky. Čte/píše do UserDefaults přes `SettingsKey`
/// a skládá `SessionConfiguration` pro spuštění nové session.
@MainActor
final class ConfigurationViewModel: ObservableObject {

    private let defaults: UserDefaults
    private let audio: AudioServiceProtocol

    // MARK: - Published state

    @Published var speed: BreathingSpeed {
        didSet { persist(speed.rawValue, forKey: SettingsKey.speed) }
    }
    @Published var rounds: Int {
        didSet { persist(rounds, forKey: SettingsKey.rounds) }
    }
    @Published var breathsBeforeRetention: Int {
        didSet { persist(breathsBeforeRetention, forKey: SettingsKey.breathsBeforeRetention) }
    }

    @Published var backgroundMusicEnabled: Bool {
        didSet { persist(backgroundMusicEnabled, forKey: SettingsKey.backgroundMusicEnabled) }
    }
    @Published var breathingPhaseMusic: Bool {
        didSet { persist(breathingPhaseMusic, forKey: SettingsKey.breathingPhaseMusic) }
    }
    @Published var breathingPhaseMusicTrack: String {
        didSet { persist(breathingPhaseMusicTrack, forKey: SettingsKey.breathingPhaseMusicTrack) }
    }
    @Published var retentionPhaseMusic: Bool {
        didSet { persist(retentionPhaseMusic, forKey: SettingsKey.retentionPhaseMusic) }
    }
    @Published var retentionPhaseMusicTrack: String {
        didSet { persist(retentionPhaseMusicTrack, forKey: SettingsKey.retentionPhaseMusicTrack) }
    }
    @Published var musicVolume: Double {
        didSet {
            persist(musicVolume, forKey: SettingsKey.musicVolume)
            audio.setMusicVolume(Float(musicVolume))
        }
    }

    @Published var guidanceEnabled: Bool {
        didSet { persist(guidanceEnabled, forKey: SettingsKey.guidanceEnabled) }
    }
    @Published var breathingPhaseGuidance: Bool {
        didSet { persist(breathingPhaseGuidance, forKey: SettingsKey.breathingPhaseGuidance) }
    }
    @Published var breathingPhaseGuidanceStyle: String {
        didSet { persist(breathingPhaseGuidanceStyle, forKey: SettingsKey.breathingPhaseGuidanceStyle) }
    }
    @Published var retentionPhaseGuidance: Bool {
        didSet { persist(retentionPhaseGuidance, forKey: SettingsKey.retentionPhaseGuidance) }
    }
    @Published var retentionPhaseGuidanceStyle: String {
        didSet { persist(retentionPhaseGuidanceStyle, forKey: SettingsKey.retentionPhaseGuidanceStyle) }
    }
    @Published var guidanceVolume: Double {
        didSet {
            persist(guidanceVolume, forKey: SettingsKey.guidanceVolume)
            audio.setGuidanceVolume(Float(guidanceVolume))
        }
    }
    @Published var retentionAnnounceInterval: Int {
        didSet { persist(retentionAnnounceInterval, forKey: SettingsKey.retentionAnnounceInterval) }
    }

    @Published var breathingSounds: Bool {
        didSet { persist(breathingSounds, forKey: SettingsKey.breathingSounds) }
    }
    @Published var breathingSoundsVoice: String {
        didSet { persist(breathingSoundsVoice, forKey: SettingsKey.breathingSoundsVoice) }
    }
    @Published var breathingSoundsVolume: Double {
        didSet {
            persist(breathingSoundsVolume, forKey: SettingsKey.breathingSoundsVolume)
            audio.setBreathingVolume(Float(breathingSoundsVolume))
        }
    }
    @Published var hapticFeedback: Bool {
        didSet { persist(hapticFeedback, forKey: SettingsKey.hapticFeedback) }
    }
    @Published var pingAndGong: Bool {
        didSet { persist(pingAndGong, forKey: SettingsKey.pingAndGong) }
    }

    private func persist<T>(_ value: T, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard, audio: AudioServiceProtocol = AudioService.shared) {
        self.defaults = defaults
        self.audio = audio
        let d = SessionConfiguration.default

        self.speed = BreathingSpeed(rawValue: defaults.string(forKey: SettingsKey.speed) ?? "") ?? d.speed
        self.rounds = defaults.object(forKey: SettingsKey.rounds) as? Int ?? d.rounds
        self.breathsBeforeRetention = defaults.object(forKey: SettingsKey.breathsBeforeRetention) as? Int ?? d.breathsBeforeRetention

        self.backgroundMusicEnabled = defaults.object(forKey: SettingsKey.backgroundMusicEnabled) as? Bool ?? d.backgroundMusicEnabled
        self.breathingPhaseMusic = defaults.object(forKey: SettingsKey.breathingPhaseMusic) as? Bool ?? d.breathingPhaseMusic
        self.breathingPhaseMusicTrack = defaults.string(forKey: SettingsKey.breathingPhaseMusicTrack) ?? d.breathingPhaseMusicTrack
        self.retentionPhaseMusic = defaults.object(forKey: SettingsKey.retentionPhaseMusic) as? Bool ?? d.retentionPhaseMusic
        self.retentionPhaseMusicTrack = defaults.string(forKey: SettingsKey.retentionPhaseMusicTrack) ?? d.retentionPhaseMusicTrack
        self.musicVolume = defaults.object(forKey: SettingsKey.musicVolume) as? Double ?? d.musicVolume

        self.guidanceEnabled = defaults.object(forKey: SettingsKey.guidanceEnabled) as? Bool ?? d.guidanceEnabled
        self.breathingPhaseGuidance = defaults.object(forKey: SettingsKey.breathingPhaseGuidance) as? Bool ?? d.breathingPhaseGuidance
        self.breathingPhaseGuidanceStyle = defaults.string(forKey: SettingsKey.breathingPhaseGuidanceStyle) ?? d.breathingPhaseGuidanceStyle
        self.retentionPhaseGuidance = defaults.object(forKey: SettingsKey.retentionPhaseGuidance) as? Bool ?? d.retentionPhaseGuidance
        self.retentionPhaseGuidanceStyle = defaults.string(forKey: SettingsKey.retentionPhaseGuidanceStyle) ?? d.retentionPhaseGuidanceStyle
        self.guidanceVolume = defaults.object(forKey: SettingsKey.guidanceVolume) as? Double ?? d.guidanceVolume
        self.retentionAnnounceInterval = defaults.object(forKey: SettingsKey.retentionAnnounceInterval) as? Int ?? d.retentionAnnounceInterval

        self.breathingSounds = defaults.object(forKey: SettingsKey.breathingSounds) as? Bool ?? d.breathingSounds
        self.breathingSoundsVoice = defaults.string(forKey: SettingsKey.breathingSoundsVoice) ?? d.breathingSoundsVoice
        self.breathingSoundsVolume = defaults.object(forKey: SettingsKey.breathingSoundsVolume) as? Double ?? d.breathingSoundsVolume
        self.hapticFeedback = defaults.object(forKey: SettingsKey.hapticFeedback) as? Bool ?? d.hapticFeedback
        self.pingAndGong = defaults.object(forKey: SettingsKey.pingAndGong) as? Bool ?? d.pingAndGong

        audio.setMusicVolume(Float(self.musicVolume))
        audio.setBreathingVolume(Float(self.breathingSoundsVolume))
        audio.setGuidanceVolume(Float(self.guidanceVolume))
    }

    // MARK: - API

    /// Vrací snapshot pro `SessionViewModel`.
    func makeSessionConfiguration() -> SessionConfiguration {
        SessionConfiguration(
            speed: speed,
            rounds: rounds,
            breathsBeforeRetention: breathsBeforeRetention,
            backgroundMusicEnabled: backgroundMusicEnabled,
            breathingPhaseMusic: breathingPhaseMusic,
            breathingPhaseMusicTrack: breathingPhaseMusicTrack,
            retentionPhaseMusic: retentionPhaseMusic,
            retentionPhaseMusicTrack: retentionPhaseMusicTrack,
            musicVolume: musicVolume,
            guidanceEnabled: guidanceEnabled,
            breathingPhaseGuidance: breathingPhaseGuidance,
            breathingPhaseGuidanceStyle: breathingPhaseGuidanceStyle,
            retentionPhaseGuidance: retentionPhaseGuidance,
            retentionPhaseGuidanceStyle: retentionPhaseGuidanceStyle,
            guidanceVolume: guidanceVolume,
            retentionAnnounceInterval: retentionAnnounceInterval,
            breathingSounds: breathingSounds,
            breathingSoundsVoice: breathingSoundsVoice,
            breathingSoundsVolume: breathingSoundsVolume,
            hapticFeedback: hapticFeedback,
            pingAndGong: pingAndGong
        )
    }

    /// Pokusí se nastavit rychlost. Pokud je premium a uživatel nemá premium,
    /// vrací `false` a volající má zobrazit paywall.
    func setSpeed(_ newSpeed: BreathingSpeed, isPremium: Bool) -> Bool {
        if newSpeed.isPremium && !isPremium {
            return false
        }
        speed = newSpeed
        return true
    }
}
