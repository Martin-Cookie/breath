import XCTest
@testable import Breath

final class WidgetDataServiceTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func session(on date: Date, retention: TimeInterval) -> Session {
        Session(
            date: date,
            speed: .standard,
            totalRounds: 1,
            breathsPerRound: 35,
            rounds: [RoundResult(roundNumber: 1, retentionTime: retention, recoveryHoldTime: 15)],
            totalDuration: 200
        )
    }

    // MARK: - Recent retentions

    func testMakeSnapshotProducesSevenRetentionPoints() {
        let today = date(2026, 4, 10)
        let snapshot = WidgetDataService.makeSnapshot(
            from: [],
            referenceDate: today,
            calendar: calendar
        )
        XCTAssertEqual(snapshot.recentRetentions.count, 7)
        XCTAssertTrue(snapshot.recentRetentions.allSatisfy { $0 == 0 })
    }

    func testMakeSnapshotMapsSessionsToCorrectDays() {
        let today = date(2026, 4, 10)
        let sessions = [
            session(on: date(2026, 4, 10), retention: 120),  // dnes
            session(on: date(2026, 4, 9), retention: 90),    // včera
            session(on: date(2026, 4, 4), retention: 60)     // mimo 7-denní okno (6 dní zpět = 4.4., ok)
        ]
        let snapshot = WidgetDataService.makeSnapshot(
            from: sessions,
            referenceDate: today,
            calendar: calendar
        )
        // Index 6 = dnes, index 5 = včera, index 0 = před 6 dny (4.4.)
        XCTAssertEqual(snapshot.recentRetentions[6], 120)
        XCTAssertEqual(snapshot.recentRetentions[5], 90)
        XCTAssertEqual(snapshot.recentRetentions[0], 60)
    }

    func testMakeSnapshotPicksBestRetentionPerDay() {
        let today = date(2026, 4, 10)
        let sessions = [
            session(on: date(2026, 4, 10), retention: 60),
            session(on: date(2026, 4, 10), retention: 150), // best of today
            session(on: date(2026, 4, 10), retention: 100)
        ]
        let snapshot = WidgetDataService.makeSnapshot(
            from: sessions,
            referenceDate: today,
            calendar: calendar
        )
        XCTAssertEqual(snapshot.recentRetentions[6], 150)
    }

    // MARK: - Streak

    func testMakeSnapshotIncludesStreakInfo() {
        let today = date(2026, 4, 10)
        let sessions = [
            session(on: date(2026, 4, 8), retention: 60),
            session(on: date(2026, 4, 9), retention: 70),
            session(on: date(2026, 4, 10), retention: 80)
        ]
        let snapshot = WidgetDataService.makeSnapshot(
            from: sessions,
            referenceDate: today,
            calendar: calendar
        )
        XCTAssertEqual(snapshot.currentStreak, 3)
        XCTAssertEqual(snapshot.bestStreak, 3)
        XCTAssertNotNil(snapshot.lastSessionDate)
    }

    // MARK: - Codable

    func testSnapshotRoundtripsCodable() throws {
        let original = WidgetSnapshot(
            currentStreak: 5,
            bestStreak: 12,
            lastSessionDate: date(2026, 4, 10),
            recentRetentions: [0, 60, 70, 80, 90, 100, 110]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        XCTAssertEqual(decoded.currentStreak, original.currentStreak)
        XCTAssertEqual(decoded.bestStreak, original.bestStreak)
        XCTAssertEqual(decoded.recentRetentions, original.recentRetentions)
    }
}
