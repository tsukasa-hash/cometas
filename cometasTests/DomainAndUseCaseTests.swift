import Foundation
import XCTest
@testable import cometas

final class DomainAndUseCaseTests: XCTestCase {
    /// 対象ファイル名: NextDueDateCalculator.swift
    /// 対象メソッド名: NextDueDateCalculator.calculate(from:interval:calendar:)
    ///
    /// 目的: 指定した interval が正しく日付加算されることを保証する。
    /// Given（前提）: UTC固定カレンダー、基準日 2026-02-28 09:00:00、interval = .tenDays。
    /// When（操作）: NextDueDateCalculator.calculate を実行する。
    /// Then（期待）: 10日後の 2026-03-10 09:00:00 を返す。
    /// 回帰リスク: 次回予定日の算出がずれ、通知・表示・履歴が不正になる。
    func testNextDueDateCalculatorAddsTenDaysWithProvidedCalendar() {
        // Given（前提）
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let baseDate = Date(timeIntervalSince1970: 1_772_336_400) // 2026-02-28 09:00:00 UTC
        let expected = Date(timeIntervalSince1970: 1_773_200_400) // 2026-03-10 09:00:00 UTC

        // When（操作）
        let result = NextDueDateCalculator.calculate(from: baseDate, interval: .tenDays, calendar: calendar)

        // Then（期待）
        XCTAssertEqual(result, expected)
    }

    /// 対象ファイル名: RecordDoneUseCase.swift
    /// 対象メソッド名: RecordDoneUseCase.execute(at:)
    ///
    /// 目的: Done実行時に設定更新・履歴追加・Widget更新が行われることを保証する。
    /// Given（前提）: task = .primary の設定、固定の計算結果を返すモック計算機。
    /// When（操作）: RecordDoneUseCase.execute(at:) を実行する。
    /// Then（期待）: lastDone/nextDue が更新され、done履歴1件追加、reloadが1回呼ばれる。
    /// 回帰リスク: 完了操作後に履歴や次回日付が更新されない。
    func testRecordDoneUseCaseUpdatesSettingsAndWritesDoneEntry() {
        // Given（前提）
        let now = Date(timeIntervalSince1970: 1_772_336_400)
        let calculatedNext = Date(timeIntervalSince1970: 1_772_941_200)

        let settings = MockSettings(
            task: .primary,
            itemName: "洗濯機フィルタ",
            interval: .oneWeek,
            nextDueDate: Date(timeIntervalSince1970: 0)
        )
        let writer = MockHistoryWriter()
        let calculator = MockCalculator(result: calculatedNext)
        let reloader = MockWidgetReloader()

        let sut = RecordDoneUseCase(
            settings: settings,
            historyWriter: writer,
            calculator: calculator,
            widgetReloader: reloader
        )

        // When（操作）
        let entry = sut.execute(at: now)

        // Then（期待）
        XCTAssertEqual(settings.lastDoneDate, now)
        XCTAssertEqual(settings.updatedNextDueDate, calculatedNext)

        XCTAssertEqual(calculator.lastBaseDate, now)
        XCTAssertEqual(calculator.lastInterval, .oneWeek)

        XCTAssertEqual(writer.appended.count, 1)
        XCTAssertEqual(entry.type, .done)
        XCTAssertEqual(entry.task, .primary)
        XCTAssertEqual(entry.date, now)
        XCTAssertEqual(entry.itemName, "洗濯機フィルタ")
        XCTAssertEqual(entry.nextDueDate, calculatedNext)

        XCTAssertEqual(reloader.reloadCount, 1)
    }

    /// 対象ファイル名: RecordDoneUseCase.swift
    /// 対象メソッド名: RecordDoneUseCase.execute(at:)
    ///
    /// 目的: secondaryタスクでも履歴の task が正しく引き継がれることを保証する。
    /// Given（前提）: task = .secondary の設定、固定の計算結果を返すモック計算機。
    /// When（操作）: RecordDoneUseCase.execute(at:) を実行する。
    /// Then（期待）: 生成された履歴 entry.task が .secondary になる。
    /// 回帰リスク: 2タスク運用時に履歴の所属タスクが混在する。
    func testRecordDoneUseCaseCreatesEntryWithSecondaryTask() {
        // Given（前提）
        let now = Date(timeIntervalSince1970: 1_772_500_000)
        let calculatedNext = Date(timeIntervalSince1970: 1_773_000_000)

        let settings = MockSettings(
            task: .secondary,
            itemName: "レンジフード",
            interval: .oneMonth,
            nextDueDate: Date(timeIntervalSince1970: 0)
        )
        let writer = MockHistoryWriter()
        let calculator = MockCalculator(result: calculatedNext)
        let reloader = MockWidgetReloader()

        let sut = RecordDoneUseCase(
            settings: settings,
            historyWriter: writer,
            calculator: calculator,
            widgetReloader: reloader
        )

        // When（操作）
        let entry = sut.execute(at: now)

        // Then（期待）
        XCTAssertEqual(entry.type, .done)
        XCTAssertEqual(entry.task, .secondary)
        XCTAssertEqual(entry.itemName, "レンジフード")
        XCTAssertEqual(entry.nextDueDate, calculatedNext)
        XCTAssertEqual(writer.appended.count, 1)
        XCTAssertEqual(reloader.reloadCount, 1)
    }

    /// 対象ファイル名: SkipUseCase.swift
    /// 対象メソッド名: SkipUseCase.execute(baseDate:)
    ///
    /// 目的: baseDate 未指定時に settings.nextDueDate が基準日として使われることを保証する。
    /// Given（前提）: settings.nextDueDate に保存済み日付、固定の計算結果を返すモック計算機。
    /// When（操作）: SkipUseCase.execute(baseDate: nil) を実行する。
    /// Then（期待）: 計算機の入力基準日と履歴日時が settings.nextDueDate になる。
    /// 回帰リスク: スキップ時の基準日がずれ、次回予定日が連鎖的にずれる。
    func testSkipUseCaseUsesStoredNextDueDateWhenBaseDateIsNil() {
        // Given（前提）
        let storedNextDueDate = Date(timeIntervalSince1970: 1_772_000_000)
        let calculatedNext = Date(timeIntervalSince1970: 1_772_864_000)

        let settings = MockSettings(
            task: .secondary,
            itemName: "換気扇",
            interval: .tenDays,
            nextDueDate: storedNextDueDate
        )
        let writer = MockHistoryWriter()
        let calculator = MockCalculator(result: calculatedNext)
        let reloader = MockWidgetReloader()

        let sut = SkipUseCase(
            settings: settings,
            historyWriter: writer,
            calculator: calculator,
            widgetReloader: reloader
        )

        // When（操作）
        let entry = sut.execute()

        // Then（期待）
        XCTAssertEqual(calculator.lastBaseDate, storedNextDueDate)
        XCTAssertEqual(calculator.lastInterval, .tenDays)

        XCTAssertEqual(settings.updatedNextDueDate, calculatedNext)

        XCTAssertEqual(writer.appended.count, 1)
        XCTAssertEqual(entry.type, .skipped)
        XCTAssertEqual(entry.task, .secondary)
        XCTAssertEqual(entry.date, storedNextDueDate)
        XCTAssertEqual(entry.itemName, "換気扇")
        XCTAssertEqual(entry.nextDueDate, calculatedNext)

        XCTAssertEqual(reloader.reloadCount, 1)
    }

    /// 対象ファイル名: SkipUseCase.swift
    /// 対象メソッド名: SkipUseCase.execute(baseDate:)
    ///
    /// 目的: baseDate 指定時は保存済みnextDueDateより指定値を優先することを保証する。
    /// Given（前提）: settings.nextDueDate と異なる explicitBaseDate、固定の計算結果を返すモック計算機。
    /// When（操作）: SkipUseCase.execute(baseDate: explicitBaseDate) を実行する。
    /// Then（期待）: 計算機入力と履歴日時が explicitBaseDate になり、nextDueは計算結果で更新される。
    /// 回帰リスク: UI指定日でのスキップが効かず、想定外の日付で履歴記録される。
    func testSkipUseCaseUsesExplicitBaseDateWhenProvided() {
        // Given（前提）
        let storedNextDueDate = Date(timeIntervalSince1970: 1_772_000_000)
        let explicitBaseDate = Date(timeIntervalSince1970: 1_772_100_000)
        let calculatedNext = Date(timeIntervalSince1970: 1_772_864_000)

        let settings = MockSettings(
            task: .primary,
            itemName: "浴室排水口",
            interval: .tenDays,
            nextDueDate: storedNextDueDate
        )
        let writer = MockHistoryWriter()
        let calculator = MockCalculator(result: calculatedNext)
        let reloader = MockWidgetReloader()

        let sut = SkipUseCase(
            settings: settings,
            historyWriter: writer,
            calculator: calculator,
            widgetReloader: reloader
        )

        // When（操作）
        let entry = sut.execute(baseDate: explicitBaseDate)

        // Then（期待）
        XCTAssertEqual(calculator.lastBaseDate, explicitBaseDate)
        XCTAssertNotEqual(calculator.lastBaseDate, storedNextDueDate)
        XCTAssertEqual(settings.updatedNextDueDate, calculatedNext)

        XCTAssertEqual(entry.type, .skipped)
        XCTAssertEqual(entry.task, .primary)
        XCTAssertEqual(entry.date, explicitBaseDate)
        XCTAssertEqual(entry.nextDueDate, calculatedNext)
        XCTAssertEqual(writer.appended.count, 1)
        XCTAssertEqual(reloader.reloadCount, 1)
    }
}

private final class MockSettings: AppSettingsAccessing {
    let task: ManagedTask
    let itemName: String
    let interval: Interval
    let nextDueDate: Date

    private(set) var lastDoneDate: Date?
    private(set) var updatedNextDueDate: Date?

    init(task: ManagedTask, itemName: String, interval: Interval, nextDueDate: Date) {
        self.task = task
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
