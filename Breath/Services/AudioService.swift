import Foundation
import AVFoundation

protocol AudioServiceProtocol: Sendable {
    func playMusic(track: String)
    func stopMusic()
    func playGuidance(key: String, style: String)
    func playBreathingIn()
    func playBreathingOut()
    func playPing()
    func playGong()
    func stopAll()
}

final class AudioService: AudioServiceProtocol, @unchecked Sendable {
    static let shared = AudioService()

    private var musicPlayer: AVAudioPlayer?
    private var guidancePlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var speechSynth: AVSpeechSynthesizer?

    /// Název stopy, která hrála před interruptem — pro případný resume.
    private var musicTrackBeforeInterruption: String?

    private init() {
        configureAudioSession()
        observeInterruptions()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioService session error: \(error)")
        }
    }

    // MARK: - Interruption handling

    private func observeInterruptions() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        center.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // Hovor / Siri / alarm — pauza hudby.
            musicPlayer?.pause()
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Zkusit obnovit přehrávání — session už může být neaktivní.
                try? AVAudioSession.sharedInstance().setActive(true)
                musicPlayer?.play()
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        // Uživatel odpojil sluchátka — pauza (jinak by hudba začala hrát z reproduktoru).
        if reason == .oldDeviceUnavailable {
            musicPlayer?.pause()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Music

    func playMusic(track: String) {
        guard let url = Bundle.main.url(forResource: track, withExtension: "m4a", subdirectory: "Audio/Music") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.5
            player.play()
            musicPlayer = player
        } catch {
            print("AudioService music error: \(error)")
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    // MARK: - Guidance (with AVSpeechSynthesizer fallback)

    func playGuidance(key: String, style: String) {
        let lang = Locale.current.language.languageCode?.identifier == "cs" ? "cs" : "en"
        if let url = Bundle.main.url(forResource: key, withExtension: "m4a", subdirectory: "Audio/Guidance/\(lang)") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 1.0
                player.play()
                guidancePlayer = player
                return
            } catch {
                print("AudioService guidance error: \(error)")
            }
        }
        speakFallback(key: key, lang: lang)
    }

    private func speakFallback(key: String, lang: String) {
        let text = guidanceFallbackText(key: key, lang: lang)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: lang == "cs" ? "cs-CZ" : "en-US")
        utterance.rate = 0.45
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        speechSynth = synth
    }

    private func guidanceFallbackText(key: String, lang: String) -> String {
        switch (key, lang) {
        case ("breathe_in", "cs"): return "Nadechněte"
        case ("breathe_out", "cs"): return "A vydechněte"
        case ("let_go", "cs"): return "Pusťte"
        case ("hold", "cs"): return "Zadržte dech"
        case ("recovery", "cs"): return "Zhluboka se nadechněte a zadržte"
        case ("breathe_in", _): return "Breathe in"
        case ("breathe_out", _): return "And let go"
        case ("let_go", _): return "Now let go"
        case ("hold", _): return "Hold your breath"
        case ("recovery", _): return "Breathe in deeply and hold"
        default: return ""
        }
    }

    // MARK: - SFX

    func playBreathingIn() { playSFX(resource: "breathing_in") }
    func playBreathingOut() { playSFX(resource: "breathing_out") }
    func playPing() { playSFX(resource: "ping") }
    func playGong() { playSFX(resource: "gong") }

    private func playSFX(resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "m4a", subdirectory: "Audio/SFX") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            sfxPlayer = player
        } catch {
            print("AudioService SFX error: \(error)")
        }
    }

    func stopAll() {
        musicPlayer?.stop()
        guidancePlayer?.stop()
        sfxPlayer?.stop()
        speechSynth?.stopSpeaking(at: .immediate)
        musicPlayer = nil
        guidancePlayer = nil
        sfxPlayer = nil
        speechSynth = nil
    }
}
