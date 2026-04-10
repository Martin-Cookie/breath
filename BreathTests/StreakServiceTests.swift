import XCTest
@testable import Breath

final class StreakServiceTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func session(on date: Date) -> Session {
        Session(
            date: date,
            speed: .standard,
            totalRounds: 3,
            breathsPerRound: 35,
            rounds: [],
            totalDuration: 0
        )
    }

    // MARK: - Empty

    func testEmptySessionsReturnsZeroStreak() {
        let info = StreakService.compute(from: [], calendar: calendar, referenceDate: date(2026, 4, 10))
        XCTAssertEqual(info.currentStreak, 0)
        XCTAssertEqual(info.bestStreak, 0)
        XCTAssertNil(info.lastSessionDate)
    }

    // MARK: - Current streak

    func testTodayOnlyYieldsStreakOne() {
        let today = date(2026, 4, 10)
        let info = StreakService.compute(from: [session(on: today)], calendar: calendar, referenceDate: today)
        XCTAssertEqual(info.currentStreak, 1)
        XCTAssertEqual(info.bestStreak, 1)
    }

    func testThreeConsecutiveDaysYieldsStreakThree() {
        let sessions = [
            session(on: date(2026, 4, 8)),
            session(on: date(2026, 4, 9)),
            session(on: date(2026, 4, 10))
        ]
        let info = StreakService.compute(from: sessions, calendar: calendar, referenceDate: date(2026, 4, 10))
        XCTAssertEqual(info.currentStreak, 3)
        XCTAssertEqual(info.bestStreak, 3)
    }

    func testMultipleSessionsSameDayCountOnce() {
        let today = date(2026, 4, 10)
        let sessions = [session(on: today), session(on: today), session(on: today)]
        let info = StreakService.compute(from: sessions, calendar: calendar, referenceDate: today)
        XCTAssertEqual(info.currentStreak, 1)
    }

    func testYesterdayOnlyStillCountsAsActiveStreak() {
        // Uživatel cvičil včera, dnes ještě ne — streak je stále 1 (neztratil ho).
        let yesterday = date(2026, 4, 9)
        let info = StreakService.compute(from: [session(on: yesterday)], calendar: calendar, referenceDate: date(2026, 4, 10))
        XCTAssertEqual(info.currentStreak, 1)
    }

    func testGapOfTwoDaysBreaksCurrentStreak() {
        // Dnes je 10.4., poslední session byla 8.4. → streak = 0 (den 9.4. chybí).
        let sessions = [session(on: date(2026, 4, 8))]
        let info = StreakService.compute(from: sessions, calendar: calendar, referenceDate: date(2026, 4, 10))
        XCTAssertEqual(info.currentStreak, 0)
    }

    // MARK: - Best streak

    func testBestStreakPicksLongestRun() {
        let sessions = [
            // Run 1: 3 dny
            session(on: date(2026, 3, 1)),
            session(on: date(2026, 3, 2)),
            session(on: date(2026, 3, 3)),
            // Gap
            // Run 2: 5 dní
            session(on: date(2026, 3, 10)),
            session(on: date(2026, 3, 11)),
            session(on: date(2026, 3, 12)),
            session(on: date(2026, 3, 13)),
            session(on: date(2026, 3, 14)),
            // Run 3: 2 dny (aktuální)
            session(on: date(2026, 4, 9)),
            session(on: date(2026, 4, 10))
        ]
        let info = StreakService.compute(from: sessions, calendar: calendar, referenceDate: date(2026, 4, 10))
        XCTAssertEqual(info.currentStreak, 2)
        XCTAssertEqual(info.bestStreak, 5)
    }

    func testLastSessionDateIsMostRecent() {
        let sessions = [
            session(on: date(2026, 4, 1)),
            session(on: date(2026, 4, 10)),
            session(on: date(2026, 4, 5))
        ]
        let info = StreakService.compute(from: sessions, calendar: calendar, referenceDate: date(2026, 4, 10))
        XCTAssertEqual(info.lastSessionDate, date(2026, 4, 10))
    }
}
