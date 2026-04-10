import Foundation
import SwiftUI

/// Uživatelská konfigurace — čtená a zapisovaná přes @AppStorage.
/// Jednotlivé klíče jsou definované v `SettingsKey` pro snadnou referenci.
enum SettingsKey {
    static let speed = "settings.speed"
    static let rounds = "settings.rounds"
    static let breathsBeforeRetention = "settings.breathsBeforeRetention"

    static let backgroundMusicEnabled = "settings.backgroundMusicEnabled"
    static let breathingPhaseMusic = "settings.breathingPhaseMusic"
    static let breathingPhaseMusicTrack = "settings.breathingPhaseMusicTrack"
    static let retentionPhaseMusic = "settings.retentionPhaseMusic"
    static let retentionPhaseMusicTrack = "settings.retentionPhaseMusicTrack"
    static let musicVolume = "settings.musicVolume"

    static let guidanceEnabled = "settings.guidanceEnabled"
    static let breathingPhaseGuidance = "settings.breathingPhaseGuidance"
    static let breathingPhaseGuidanceStyle = "settings.breathingPhaseGuidanceStyle"
    static let retentionPhaseGuidance = "settings.retentionPhaseGuidance"
    static let retentionPhaseGuidanceStyle = "settings.retentionPhaseGuidanceStyle"
    static let guidanceVolume = "settings.guidanceVolume"
    static let retentionAnnounceInterval = "settings.retentionAnnounceInterval"

    static let breathingSounds = "settings.breathingSounds"
    static let breathingSoundsVoice = "settings.breathingSoundsVoice"
    static let breathingSoundsVolume = "settings.breathingSoundsVolume"
    static let hapticFeedback = "settings.hapticFeedback"
    static let pingAndGong = "settings.pingAndGong"

    static let notificationsEnabled = "settings.notificationsEnabled"
    static let notificationHour = "settings.notificationHour"
    static let notificationMinute = "settings.notificationMinute"

    static let isPremium = "settings.isPremium"

    static let hasSeenOnboarding = "settings.hasSeenOnboarding"

    static let currentStreak = "stats.currentStreak"
    static let bestStreak = "stats.bestStreak"
    static let lastSessionDate = "stats.lastSessionDate"
}

/// Hodnotový snapshot konfigurace — předává se do ViewModels a services.
struct SessionConfiguration: Equatable {
    var speed: BreathingSpeed
    var rounds: Int
    var breathsBeforeRetention: Int

    var backgroundMusicEnabled: Bool
    var breathingPhaseMusic: Bool
    var breathingPhaseMusicTrack: String
    var retentionPhaseMusic: Bool
    var retentionPhaseMusicTrack: String
    var musicVolume: Double

    var guidanceEnabled: Bool
    var breathingPhaseGuidance: Bool
    var breathingPhaseGuidanceStyle: String
    var retentionPhaseGuidance: Bool
    var retentionPhaseGuidanceStyle: String
    var guidanceVolume: Double
    var retentionAnnounceInterval: Int

    var breathingSounds: Bool
    var breathingSoundsVoice: String
    var breathingSoundsVolume: Double
    var hapticFeedback: Bool
    var pingAndGong: Bool

    static let `default` = SessionConfiguration(
        speed: .standard,
        rounds: 3,
        breathsBeforeRetention: 35,
        backgroundMusicEnabled: true,
        breathingPhaseMusic: true,
        breathingPhaseMusicTrack: "sweet_and_spicy",
        retentionPhaseMusic: true,
        retentionPhaseMusicTrack: "sweet_and_spicy",
        musicVolume: 0.5,
        guidanceEnabled: true,
        breathingPhaseGuidance: true,
        breathingPhaseGuidanceStyle: "classic",
        retentionPhaseGuidance: true,
        retentionPhaseGuidanceStyle: "classic",
        guidanceVolume: 1.0,
        retentionAnnounceInterval: 0,
        breathingSounds: true,
        breathingSoundsVoice: "male",
        breathingSoundsVolume: 1.0,
        hapticFeedback: false,
        pingAndGong: true
    )
}
