import Foundation
import XCTest
@testable import cometas

final class DatePresentationTests: XCTestCase {
    /// 期限超過時に「超過」という文言ではなく、負数の日数で表示することを保証する。
    func testRemainingDaysTextUsesMinusSignForOverdueDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_772_409_600) // 2026-03-01 00:00:00 UTC
        let dueDate = Date(timeIntervalSince1970: 1_772_236_800) // 2026-02-27 00:00:00 UTC

        let text = DatePresentation.remainingDaysText(
            until: dueDate,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(text, "-2日")
    }
}
