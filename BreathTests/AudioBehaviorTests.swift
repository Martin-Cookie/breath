import XCTest
@testable import Breath

@MainActor
final class AudioBehaviorTests: XCTestCase {

    func testSpeakRetentionTimeRecordsSeconds() {
        let mock = MockAudioService()
        mock.speakRetentionTime(seconds: 30)
        XCTAssertTrue(mock.calls.contains(.speakRetentionTime(30)))
    }

    func testPlayBreathingInFemaleRecordsVoice() {
        let mock = MockAudioService()
        mock.playBreathingIn(voice: "female")
        XCTAssertTrue(mock.calls.contains(.playBreathingIn("female")))
    }
}
