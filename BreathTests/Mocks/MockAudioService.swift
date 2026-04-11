import Foundation
@testable import Breath

/// Testovací fake — zaznamenává všechny volání pro verifikaci v testech.
final class MockAudioService: AudioServiceProtocol {

    enum Call: Equatable {
        case playMusic(String)
        case stopMusic
        case setMusicVolume(Float)
        case previewMusic(String)
        case stopPreview
        case setGuidanceVolume(Float)
        case playGuidance(String, String)
        case speakRetentionTime(Int)
        case setBreathingVolume(Float)
        case playBreathingIn(String)
        case playBreathingOut(String)
        case previewBreathing(String)
        case playPing
        case playGong
        case playWarning
        case stopAll
    }

    nonisolated(unsafe) private(set) var calls: [Call] = []

    func playMusic(track: String) { calls.append(.playMusic(track)) }
    func stopMusic() { calls.append(.stopMusic) }
    func setMusicVolume(_ volume: Float) { calls.append(.setMusicVolume(volume)) }
    func previewMusic(track: String) { calls.append(.previewMusic(track)) }
    func stopPreview() { calls.append(.stopPreview) }
    func setGuidanceVolume(_ volume: Float) { calls.append(.setGuidanceVolume(volume)) }
    func playGuidance(key: String, style: String) { calls.append(.playGuidance(key, style)) }
    func speakRetentionTime(seconds: Int) { calls.append(.speakRetentionTime(seconds)) }
    func setBreathingVolume(_ volume: Float) { calls.append(.setBreathingVolume(volume)) }
    func playBreathingIn(voice: String) { calls.append(.playBreathingIn(voice)) }
    func playBreathingOut(voice: String) { calls.append(.playBreathingOut(voice)) }
    func previewBreathing(voice: String) { calls.append(.previewBreathing(voice)) }
    func playPing() { calls.append(.playPing) }
    func playGong() { calls.append(.playGong) }
    func playWarning() { calls.append(.playWarning) }
    func stopAll() { calls.append(.stopAll) }
}

final class MockHapticService: HapticServiceProtocol {
    nonisolated(unsafe) private(set) var impacts: [HapticService.Style] = []
    nonisolated(unsafe) private(set) var notifications: [HapticService.Notification] = []

    func impact(_ style: HapticService.Style) { impacts.append(style) }
    func notify(_ type: HapticService.Notification) { notifications.append(type) }
}
