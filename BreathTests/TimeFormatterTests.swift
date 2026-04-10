import XCTest
@testable import Breath

final class TimeFormatterTests: XCTestCase {

    func testZeroSecondsFormatsAsZeroColonZeroZero() {
        XCTAssertEqual(TimeFormatter.mmss(0), "0:00")
    }

    func testSubSecondRoundsToNearestSecond() {
        XCTAssertEqual(TimeFormatter.mmss(0.4), "0:00")
        XCTAssertEqual(TimeFormatter.mmss(0.6), "0:01")
    }

    func testUnderMinutePadsSeconds() {
        XCTAssertEqual(TimeFormatter.mmss(7), "0:07")
        XCTAssertEqual(TimeFormatter.mmss(59), "0:59")
    }

    func testExactMinute() {
        XCTAssertEqual(TimeFormatter.mmss(60), "1:00")
        XCTAssertEqual(TimeFormatter.mmss(125), "2:05")
    }

    func testAboveOneHourIncludesHours() {
        XCTAssertEqual(TimeFormatter.mmss(3600), "1:00:00")
        XCTAssertEqual(TimeFormatter.mmss(3661), "1:01:01")
    }

    func testSignedDiffPositive() {
        XCTAssertEqual(TimeFormatter.signedDiff(15), "+0:15")
    }

    func testSignedDiffNegative() {
        XCTAssertEqual(TimeFormatter.signedDiff(-5), "-0:05")
    }

    func testSignedDiffZeroIsPositive() {
        XCTAssertEqual(TimeFormatter.signedDiff(0), "+0:00")
    }
}
