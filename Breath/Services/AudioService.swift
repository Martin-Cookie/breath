import Foundation
import AVFoundation

protocol AudioServiceProtocol: Sendable {
    func playMusic(track: String)
    func stopMusic()
    func setMusicVolume(_ volume: Float)
    func previewMusic(track: String)
    func stopPreview()
    func setGuidanceVolume(_ volume: Float)
    func playGuidance(key: String, style: String)
    func speakRetentionTime(seconds: Int)
    func setBreathingVolume(_ volume: Float)
    func playBreathingIn(voice: String)
    func playBreathingOut(voice: String)
    func previewBreathing(voice: String)
    func playPing()
    func playGong()
    func playWarning()
    func stopAll()
}

final class AudioService: AudioServiceProtocol, @unchecked Sendable {
    static let shared = AudioService()

    private var musicPlayer: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    private var guidancePlayer: AVAudioPlayer?
    private var breathPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var speechSynth: AVSpeechSynthesizer?

    /// Hlasitost hudby (0.0 – 1.0). Aplikuje se na aktuálně hrajícího `musicPlayer` i na nové přehrávání.
    private var musicVolume: Float = 0.5
    /// Hlasitost zvuků dýchání (0.0 – 1.0).
    private var breathingVolume: Float = 1.0
    /// Hlasitost hlasového vedení (0.0 – 1.0).
    private var guidanceVolume: Float = 1.0

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
        guard let url = Bundle.main.url(forResource: track, withExtension: "m4a") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = musicVolume
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

    func setMusicVolume(_ volume: Float) {
        let clamped = max(0, min(1, volume))
        musicVolume = clamped
        musicPlayer?.volume = clamped
        previewPlayer?.volume = clamped
    }

    func previewMusic(track: String) {
        stopPreview()
        guard let url = Bundle.main.url(forResource: track, withExtension: "m4a") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = musicVolume
            player.play()
            previewPlayer = player
        } catch {
            print("AudioService preview error: \(error)")
        }
    }

    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
    }

    // MARK: - Guidance (with AVSpeechSynthesizer fallback)

    func setGuidanceVolume(_ volume: Float) {
        let clamped = max(0, min(1, volume))
        guidanceVolume = clamped
        guidancePlayer?.volume = clamped
    }

    func playGuidance(key: String, style: String) {
        let lang = Locale.current.language.languageCode?.identifier == "cs" ? "cs" : "en"
        // Resolver chain:
        //   1) "<style>_<key>_<lang>.m4a"  (style-specific, localized)
        //   2) "<key>_<lang>.m4a"          (style-agnostic, localized)
        //   3) "<key>.m4a"                 (style-agnostic, language-agnostic)
        //   4) speech synth fallback
        let candidates = [
            "\(style)_\(key)_\(lang)",
            "\(key)_\(lang)",
            key
        ]
        for name in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "m4a") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.volume = guidanceVolume
                    player.play()
                    guidancePlayer = player
                    return
                } catch {
                    print("AudioService guidance error: \(error)")
                }
            }
        }
        speakFallback(key: key, lang: lang)
    }

    func speakRetentionTime(seconds: Int) {
        let lang = Locale.current.language.languageCode?.identifier == "cs" ? "cs" : "en"
        // Language-agnostic short form avoids plural grammar pitfalls.
        let text = "\(seconds) s"
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: lang == "cs" ? "cs-CZ" : "en-US")
        utt.rate = 0.45
        utt.volume = guidanceVolume
        let synth = AVSpeechSynthesizer()
        synth.speak(utt)
        speechSynth = synth
    }

    private func speakFallback(key: String, lang: String) {
        let text = guidanceFallbackText(key: key, lang: lang)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: lang == "cs" ? "cs-CZ" : "en-US")
        utterance.rate = 0.45
        utterance.volume = guidanceVolume
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        speechSynth = synth
    }

    private func guidanceFallbackText(key: String, lang: String) -> String {
        switch (key, lang) {
        case ("breathe_in", "cs"): return "Nadechněte"
        case ("let_go", "cs"): return "Pusťte"
        case ("hold", "cs"): return "Zadržte dech"
        case ("recovery", "cs"): return "Zhluboka se nadechněte a zadržte"
        case ("breathe_in", _): return "Breathe in"
        case ("let_go", _): return "Now let go"
        case ("hold", _): return "Hold your breath"
        case ("recovery", _): return "Breathe in deeply and hold"
        default: return ""
        }
    }

    // MARK: - SFX

    func setBreathingVolume(_ volume: Float) {
        let clamped = max(0, min(1, volume))
        breathingVolume = clamped
    }

    func playBreathingIn(voice: String) { playBreath(base: "breathing_in", voice: voice) }
    func playBreathingOut(voice: String) { playBreath(base: "breathing_out", voice: voice) }

    func previewBreathing(voice: String) {
        playBreath(base: "breathing_in", voice: voice)
    }

    private func playBreath(base: String, voice: String) {
        let suffixed = voice == "female" ? "\(base)_female" : base
        let url = Bundle.main.url(forResource: suffixed, withExtension: "m4a")
            ?? Bundle.main.url(forResource: base, withExtension: "m4a")
        guard let url else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = breathingVolume
            player.play()
            breathPlayer = player
        } catch {
            print("AudioService breath error: \(error)")
        }
    }

    func playPing() { playSFX(resource: "ping") }
    func playGong() { playSFX(resource: "gong") }
    func playWarning() { playSFX(resource: "warning") }

    private func playSFX(resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "m4a") else {
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
        previewPlayer?.stop()
        guidancePlayer?.stop()
        breathPlayer?.stop()
        sfxPlayer?.stop()
        speechSynth?.stopSpeaking(at: .immediate)
        musicPlayer = nil
        previewPlayer = nil
        guidancePlayer = nil
        breathPlayer = nil
        sfxPlayer = nil
        speechSynth = nil
    }
}
