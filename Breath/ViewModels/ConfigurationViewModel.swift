import Foundation
import SwiftUI
import Combine

/// Držitel stavu konfigurační obrazovky. Čte/píše do UserDefaults přes `SettingsKey`
/// a skládá `SessionConfiguration` pro spuštění nové session.
@MainActor
final class ConfigurationViewModel: ObservableObject {

    private let defaults: UserDefaults

    // MARK: - Published state

    @Published var speed: BreathingSpeed {
        didSet { defaults.set(speed.rawValue, forKey: SettingsKey.speed) }
    }
    @Published var rounds: Int {
        didSet { defaults.set(rounds, forKey: SettingsKey.rounds) }
    }
    @Published var breathsBeforeRetention: Int {
        didSet { defaults.set(breathsBeforeRetention, forKey: SettingsKey.breathsBeforeRetention) }
    }

    @Published var backgroundMusicEnabled: Bool {
        didSet { defaults.set(backgroundMusicEnabled, forKey: SettingsKey.backgroundMusicEnabled) }
    }
    @Published var breathingPhaseMusic: Bool {
        didSet { defaults.set(breathingPhaseMusic, forKey: SettingsKey.breathingPhaseMusic) }
    }
    @Published var breathingPhaseMusicTrack: String {
        didSet { defaults.set(breathingPhaseMusicTrack, forKey: SettingsKey.breathingPhaseMusicTrack) }
    }
    @Published var retentionPhaseMusic: Bool {
        didSet { defaults.set(retentionPhaseMusic, forKey: SettingsKey.retentionPhaseMusic) }
    }
    @Published var retentionPhaseMusicTrack: String {
        didSet { defaults.set(retentionPhaseMusicTrack, forKey: SettingsKey.retentionPhaseMusicTrack) }
    }

    @Published var guidanceEnabled: Bool {
        didSet { defaults.set(guidanceEnabled, forKey: SettingsKey.guidanceEnabled) }
    }
    @Published var breathingPhaseGuidance: Bool {
        didSet { defaults.set(breathingPhaseGuidance, forKey: SettingsKey.breathingPhaseGuidance) }
    }
    @Published var breathingPhaseGuidanceStyle: String {
        didSet { defaults.set(breathingPhaseGuidanceStyle, forKey: SettingsKey.breathingPhaseGuidanceStyle) }
    }
    @Published var retentionPhaseGuidance: Bool {
        didSet { defaults.set(retentionPhaseGuidance, forKey: SettingsKey.retentionPhaseGuidance) }
    }
    @Published var retentionPhaseGuidanceStyle: String {
        didSet { defaults.set(retentionPhaseGuidanceStyle, forKey: SettingsKey.retentionPhaseGuidanceStyle) }
    }

    @Published var breathingSounds: Bool {
        didSet { defaults.set(breathingSounds, forKey: SettingsKey.breathingSounds) }
    }
    @Published var hapticFeedback: Bool {
        didSet { defaults.set(hapticFeedback, forKey: SettingsKey.hapticFeedback) }
    }
    @Published var pingAndGong: Bool {
        didSet { defaults.set(pingAndGong, forKey: SettingsKey.pingAndGong) }
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let d = SessionConfiguration.default

        self.speed = BreathingSpeed(rawValue: defaults.string(forKey: SettingsKey.speed) ?? "") ?? d.speed
        self.rounds = defaults.object(forKey: SettingsKey.rounds) as? Int ?? d.rounds
        self.breathsBeforeRetention = defaults.object(forKey: SettingsKey.breathsBeforeRetention) as? Int ?? d.breathsBeforeRetention

        self.backgroundMusicEnabled = defaults.object(forKey: SettingsKey.backgroundMusicEnabled) as? Bool ?? d.backgroundMusicEnabled
        self.breathingPhaseMusic = defaults.object(forKey: SettingsKey.breathingPhaseMusic) as? Bool ?? d.breathingPhaseMusic
        self.breathingPhaseMusicTrack = defaults.string(forKey: SettingsKey.breathingPhaseMusicTrack) ?? d.breathingPhaseMusicTrack
        self.retentionPhaseMusic = defaults.object(forKey: SettingsKey.retentionPhaseMusic) as? Bool ?? d.retentionPhaseMusic
        self.retentionPhaseMusicTrack = defaults.string(forKey: SettingsKey.retentionPhaseMusicTrack) ?? d.retentionPhaseMusicTrack

        self.guidanceEnabled = defaults.object(forKey: SettingsKey.guidanceEnabled) as? Bool ?? d.guidanceEnabled
        self.breathingPhaseGuidance = defaults.object(forKey: SettingsKey.breathingPhaseGuidance) as? Bool ?? d.breathingPhaseGuidance
        self.breathingPhaseGuidanceStyle = defaults.string(forKey: SettingsKey.breathingPhaseGuidanceStyle) ?? d.breathingPhaseGuidanceStyle
        self.retentionPhaseGuidance = defaults.object(forKey: SettingsKey.retentionPhaseGuidance) as? Bool ?? d.retentionPhaseGuidance
        self.retentionPhaseGuidanceStyle = defaults.string(forKey: SettingsKey.retentionPhaseGuidanceStyle) ?? d.retentionPhaseGuidanceStyle

        self.breathingSounds = defaults.object(forKey: SettingsKey.breathingSounds) as? Bool ?? d.breathingSounds
        self.hapticFeedback = defaults.object(forKey: SettingsKey.hapticFeedback) as? Bool ?? d.hapticFeedback
        self.pingAndGong = defaults.object(forKey: SettingsKey.pingAndGong) as? Bool ?? d.pingAndGong
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
            guidanceEnabled: guidanceEnabled,
            breathingPhaseGuidance: breathingPhaseGuidance,
            breathingPhaseGuidanceStyle: breathingPhaseGuidanceStyle,
            retentionPhaseGuidance: retentionPhaseGuidance,
            retentionPhaseGuidanceStyle: retentionPhaseGuidanceStyle,
            breathingSounds: breathingSounds,
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
