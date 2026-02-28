import Foundation
import XCTest
@testable import cometas

final class DomainAndUseCaseTests: XCTestCase {
    func testNextDueDateCalculatorAddsTenDaysWithProvidedCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let baseDate = Date(timeIntervalSince1970: 1_772_336_400) // 2026-02-28 09:00:00 UTC

        let result = NextDueDateCalculator.calculate(from: baseDate, interval: .tenDays, calendar: calendar)
        let expected = Date(timeIntervalSince1970: 1_773_200_400) // 2026-03-10 09:00:00 UTC

        XCTAssertEqual(result, expected)
    }

    func testRecordDoneUseCaseUpdatesSettingsAndWritesDoneEntry() {
        let now = Date(timeIntervalSince1970: 1_772_336_400)
        let calculatedNext = Date(timeIntervalSince1970: 1_772_941_200)

        let settings = MockSettings(itemName: "洗濯機フィルタ", interval: .oneWeek, nextDueDate: Date(timeIntervalSince1970: 0))
        let writer = MockHistoryWriter()
        let calculator = MockCalculator(result: calculatedNext)
        let reloader = MockWidgetReloader()

        let sut = RecordDoneUseCase(
            settings: settings,
            historyWriter: writer,
            calculator: calculator,
            widgetReloader: reloader
        )

        let entry = sut.execute(at: now)

        XCTAssertEqual(settings.lastDoneDate, now)
        XCTAssertEqual(settings.updatedNextDueDate, calculatedNext)

        XCTAssertEqual(calculator.lastBaseDate, now)
        XCTAssertEqual(calculator.lastInterval, .oneWeek)

        XCTAssertEqual(writer.appended.count, 1)
        XCTAssertEqual(entry.type, .done)
        XCTAssertEqual(entry.date, now)
        XCTAssertEqual(entry.itemName, "洗濯機フィルタ")
        XCTAssertEqual(entry.nextDueDate, calculatedNext)

        XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testSkipUseCaseUsesStoredNextDueDateWhenBaseDateIsNil() {
        let storedNextDueDate = Date(timeIntervalSince1970: 1_772_000_000)
        let calculatedNext = Date(timeIntervalSince1970: 1_772_864_000)

        let settings = MockSettings(itemName: "換気扇", interval: .tenDays, nextDueDate: storedNextDueDate)
        let writer = MockHistoryWriter()
        let calculator = MockCalculator(result: calculatedNext)
        let reloader = MockWidgetReloader()

        let sut = SkipUseCase(
            settings: settings,
            historyWriter: writer,
            calculator: calculator,
            widgetReloader: reloader
        )

        let entry = sut.execute()

        XCTAssertEqual(calculator.lastBaseDate, storedNextDueDate)
        XCTAssertEqual(calculator.lastInterval, .tenDays)

        XCTAssertEqual(settings.updatedNextDueDate, calculatedNext)

        XCTAssertEqual(writer.appended.count, 1)
        XCTAssertEqual(entry.type, .skipped)
        XCTAssertEqual(entry.date, storedNextDueDate)
        XCTAssertEqual(entry.itemName, "換気扇")
        XCTAssertEqual(entry.nextDueDate, calculatedNext)

        XCTAssertEqual(reloader.reloadCount, 1)
    }
}

private final class MockSettings: AppSettingsAccessing {
    let itemName: String
    let interval: Interval
    let nextDueDate: Date

    private(set) var lastDoneDate: Date?
    private(set) var updatedNextDueDate: Date?

    init(itemName: String, interval: Interval, nextDueDate: Date) {
        self.itemName = itemName
        self.interval = interval
        self.nextDueDate = nextDueDate
    }

    func setLastDoneDate(_ date: Date) {
        lastDoneDate = date
    }

    func setNextDueDate(_ date: Date) {
        updatedNextDueDate = date
    }
}

private final class MockHistoryWriter: HistoryEntryWriting {
    private(set) var appended: [HistoryEntry] = []

    func append(_ entry: HistoryEntry) {
        appended.append(entry)
    }
}

private final class MockCalculator: NextDueDateCalculating {
    private let result: Date

    private(set) var lastBaseDate: Date?
    private(set) var lastInterval: Interval?

    init(result: Date) {
        self.result = result
    }

    func calculate(from baseDate: Date, interval: Interval) -> Date {
        lastBaseDate = baseDate
        lastInterval = interval
        return result
    }
}

private final class MockWidgetReloader: WidgetTimelineReloading {
    private(set) var reloadCount = 0

    func reload() {
        reloadCount += 1
    }
}
