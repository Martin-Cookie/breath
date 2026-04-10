import Foundation
@testable import Breath

/// Testovací fake — zaznamenává všechny volání pro verifikaci v testech.
final class MockAudioService: AudioServiceProtocol {

    enum Call: Equatable {
        case playMusic(String)
        case stopMusic
        case playGuidance(String, String)
        case playBreathingIn
        case playBreathingOut
        case playPing
        case playGong
        case stopAll
    }

    private(set) var calls: [Call] = []

    func playMusic(track: String) { calls.append(.playMusic(track)) }
    func stopMusic() { calls.append(.stopMusic) }
    func playGuidance(key: String, style: String) { calls.append(.playGuidance(key, style)) }
    func playBreathingIn() { calls.append(.playBreathingIn) }
    func playBreathingOut() { calls.append(.playBreathingOut) }
    func playPing() { calls.append(.playPing) }
    func playGong() { calls.append(.playGong) }
    func stopAll() { calls.append(.stopAll) }
}

final class MockHapticService: HapticServiceProtocol {
    private(set) var impacts: [HapticService.Style] = []
    private(set) var notifications: [HapticService.Notification] = []

    func impact(_ style: HapticService.Style) { impacts.append(style) }
    func notify(_ type: HapticService.Notification) { notifications.append(type) }
}
