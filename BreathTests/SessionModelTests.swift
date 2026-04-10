import XCTest
@testable import Breath

final class SessionModelTests: XCTestCase {

    private func round(_ number: Int, retention: TimeInterval) -> RoundResult {
        RoundResult(roundNumber: number, retentionTime: retention, recoveryHoldTime: 15)
    }

    // MARK: - Rounds encoding

    func testRoundsArePersistedThroughGetterSetter() {
        let session = Session(
            speed: .standard,
            totalRounds: 3,
            breathsPerRound: 35,
            rounds: [round(1, retention: 60), round(2, retention: 75), round(3, retention: 90)],
            totalDuration: 300
        )
        XCTAssertEqual(session.rounds.count, 3)
        XCTAssertEqual(session.rounds[0].retentionTime, 60)
        XCTAssertEqual(session.rounds[2].retentionTime, 90)
    }

    func testEmptyRoundsArrayIsHandled() {
        let session = Session(
            speed: .standard,
            totalRounds: 0,
            breathsPerRound: 0,
            rounds: [],
            totalDuration: 0
        )
        XCTAssertTrue(session.rounds.isEmpty)
        XCTAssertEqual(session.bestRetention, 0)
        XCTAssertEqual(session.averageRetention, 0)
    }

    // MARK: - Computed properties

    func testBestRetentionReturnsMax() {
        let session = Session(
            speed: .fast,
            totalRounds: 3,
            breathsPerRound: 40,
            rounds: [round(1, retention: 45), round(2, retention: 120), round(3, retention: 80)],
            totalDuration: 500
        )
        XCTAssertEqual(session.bestRetention, 120)
    }

    func testAverageRetentionIsMean() {
        let session = Session(
            speed: .standard,
            totalRounds: 3,
            breathsPerRound: 30,
            rounds: [round(1, retention: 60), round(2, retention: 90), round(3, retention: 120)],
            totalDuration: 400
        )
        XCTAssertEqual(session.averageRetention, 90, accuracy: 0.01)
    }

    // MARK: - Speed proxy

    func testSpeedProxyReadsAndWrites() {
        let session = Session(
            speed: .slow,
            totalRounds: 2,
            breathsPerRound: 30,
            rounds: [],
            totalDuration: 0
        )
        XCTAssertEqual(session.speed, .slow)
        session.speed = .fast
        XCTAssertEqual(session.speedRaw, "fast")
    }

    func testSpeedProxyFallsBackToStandardOnInvalidRaw() {
        let session = Session(
            speed: .standard,
            totalRounds: 1,
            breathsPerRound: 30,
            rounds: [],
            totalDuration: 0
        )
        session.speedRaw = "invalid_value"
        XCTAssertEqual(session.speed, .standard)
    }

    // MARK: - Rounds mutation

    func testRoundsSetterReplacesAll() {
        let session = Session(
            speed: .standard,
            totalRounds: 2,
            breathsPerRound: 35,
            rounds: [round(1, retention: 60)],
            totalDuration: 100
        )
        XCTAssertEqual(session.rounds.count, 1)
        session.rounds = [round(1, retention: 70), round(2, retention: 80)]
        XCTAssertEqual(session.rounds.count, 2)
        XCTAssertEqual(session.bestRetention, 80)
    }
}
