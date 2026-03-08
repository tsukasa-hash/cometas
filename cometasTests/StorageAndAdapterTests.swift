import Foundation
import XCTest
@testable import cometas

final class StorageAndAdapterTests: XCTestCase {
    /// 対象ファイル名: AppSettings.swift
    /// 対象メソッド名: AppSettings.setItemName(_:task:defaults:), AppSettings.itemName(task:defaults:)
    ///
    /// 目的: primary/secondary の item キーが分離されることを保証する。
    /// Given（前提）: primary に "A"、secondary に "B" を保存する。
    /// When（操作）: task 指定で itemName を取得する。
    /// Then（期待）: primary は "A"、secondary は "B" を返す。
    /// 回帰リスク: task間で項目名が上書きされ、別タスクの表示が壊れる。
    func testAppSettingsPrimaryItemDoesNotAffectSecondaryItem() {
        // Given（前提）
        let suite = "cometas.tests.appsettings.item.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        AppSettings.setItemName("A", task: .primary, defaults: defaults)
        AppSettings.setItemName("B", task: .secondary, defaults: defaults)

        // When（操作）
        let primary = AppSettings.itemName(task: .primary, defaults: defaults)
        let secondary = AppSettings.itemName(task: .secondary, defaults: defaults)

        // Then（期待）
        XCTAssertEqual(primary, "A")
        XCTAssertEqual(secondary, "B")
    }

    /// 対象ファイル名: AppSettings.swift
    /// 対象メソッド名: AppSettings.setInterval(_:task:defaults:), AppSettings.interval(task:defaults:)
    ///
    /// 目的: primary/secondary の interval キーが分離されることを保証する。
    /// Given（前提）: primary=.oneWeek、secondary=.sixMonths を保存する。
    /// When（操作）: task 指定で interval を取得する。
    /// Then（期待）: primary は .oneWeek、secondary は .sixMonths を返す。
    /// 回帰リスク: 間隔設定がタスク間で混在し、次回日付計算が誤る。
    func testAppSettingsPrimaryIntervalDoesNotAffectSecondaryInterval() {
        // Given（前提）
        let suite = "cometas.tests.appsettings.interval.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        AppSettings.setInterval(.oneWeek, task: .primary, defaults: defaults)
        AppSettings.setInterval(.sixMonths, task: .secondary, defaults: defaults)

        // When（操作）
        let primary = AppSettings.interval(task: .primary, defaults: defaults)
        let secondary = AppSettings.interval(task: .secondary, defaults: defaults)

        // Then（期待）
        XCTAssertEqual(primary, .oneWeek)
        XCTAssertEqual(secondary, .sixMonths)
    }

    /// 対象ファイル名: AppSettings.swift
    /// 対象メソッド名: AppSettings.setLastDoneDate(_:task:defaults:), AppSettings.lastDoneDate(task:defaults:),
    /// AppSettings.setNextDueDate(_:task:defaults:), AppSettings.nextDueDate(task:defaults:)
    ///
    /// 目的: primary/secondary の日付キーが分離されることを保証する。
    /// Given（前提）: 各taskに異なる lastDoneDate/nextDueDate を保存する。
    /// When（操作）: task 指定で各日付を取得する。
    /// Then（期待）: それぞれ保存した日付をそのまま返す。
    /// 回帰リスク: 日付が他タスクの値に置き換わり、予定管理が破綻する。
    func testAppSettingsPrimaryDatesDoNotAffectSecondaryDates() {
        // Given（前提）
        let suite = "cometas.tests.appsettings.dates.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let primaryLast = Date(timeIntervalSince1970: 1_700_000_000)
        let primaryNext = Date(timeIntervalSince1970: 1_700_100_000)
        let secondaryLast = Date(timeIntervalSince1970: 1_710_000_000)
        let secondaryNext = Date(timeIntervalSince1970: 1_710_100_000)

        AppSettings.setLastDoneDate(primaryLast, task: .primary, defaults: defaults)
        AppSettings.setNextDueDate(primaryNext, task: .primary, defaults: defaults)
        AppSettings.setLastDoneDate(secondaryLast, task: .secondary, defaults: defaults)
        AppSettings.setNextDueDate(secondaryNext, task: .secondary, defaults: defaults)

        // When（操作）
        let loadedPrimaryLast = AppSettings.lastDoneDate(task: .primary, defaults: defaults)
        let loadedPrimaryNext = AppSettings.nextDueDate(task: .primary, defaults: defaults)
        let loadedSecondaryLast = AppSettings.lastDoneDate(task: .secondary, defaults: defaults)
        let loadedSecondaryNext = AppSettings.nextDueDate(task: .secondary, defaults: defaults)

        // Then（期待）
        XCTAssertEqual(loadedPrimaryLast, primaryLast)
        XCTAssertEqual(loadedPrimaryNext, primaryNext)
        XCTAssertEqual(loadedSecondaryLast, secondaryLast)
        XCTAssertEqual(loadedSecondaryNext, secondaryNext)
    }

    /// 対象ファイル名: AppSettings.swift
    /// 対象メソッド名: AppSettings.interval(task:defaults:)
    ///
    /// 目的: interval の保存値が不正でも安全にデフォルト値へフォールバックすることを保証する。
    /// Given（前提）: intervalRawValue に不正文字列を保存する。
    /// When（操作）: AppSettings.interval(task: .primary, defaults:) を取得する。
    /// Then（期待）: .twoMonths を返す。
    /// 回帰リスク: 壊れた設定値でクラッシュや予期せぬ間隔が使われる。
    func testAppSettingsIntervalFallsBackToDefaultWhenRawValueIsInvalid() {
        // Given（前提）
        let suite = "cometas.tests.appsettings.invalid.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set("not-an-interval", forKey: "intervalRawValue")

        // When（操作）
        let loaded = AppSettings.interval(task: .primary, defaults: defaults)

        // Then（期待）
        XCTAssertEqual(loaded, .twoMonths)
    }

    /// 対象ファイル名: AppSettings.swift
    /// 対象メソッド名: AppSettings.setWidgetDisplayTaskOption(_:defaults:), AppSettings.widgetDisplayTaskOption(defaults:)
    ///
    /// 目的: Widget表示対象の設定値が保存・復元されることを保証する。
    /// Given（前提）: `.task2` を保存する。
    /// When（操作）: 設定値を再取得する。
    /// Then（期待）: `.task2` を返す。
    /// 回帰リスク: 設定画面の選択がWidget表示に反映されない。
    func testWidgetDisplayTaskOptionPersistsSelectedValue() {
        // Given（前提）
        let suite = "cometas.tests.appsettings.widget.option.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        AppSettings.setWidgetDisplayTaskOption(.task2, defaults: defaults)

        // When（操作）
        let loaded = AppSettings.widgetDisplayTaskOption(defaults: defaults)

        // Then（期待）
        XCTAssertEqual(loaded, .task2)
    }

    /// 対象ファイル名: AppSettings.swift
    /// 対象メソッド名: AppSettings.widgetDisplayTask(defaults:)
    ///
    /// 目的: 期限が短いもの選択時に nextDueDate が近い task を返すことを保証する。
    /// Given（前提）: primary の期限を secondary より遅く保存し、設定を `.shortestDue` にする。
    /// When（操作）: 表示対象 task を取得する。
    /// Then（期待）: `.secondary` を返す。
    /// 回帰リスク: Widget が「期限が短いもの」と異なるタスクを表示する。
    func testWidgetDisplayTaskUsesShortestDueOption() {
        // Given（前提）
        let suite = "cometas.tests.appsettings.widget.shortest.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let primaryNext = Date(timeIntervalSince1970: 1_800_000_000)
        let secondaryNext = Date(timeIntervalSince1970: 1_700_000_000)
        AppSettings.setNextDueDate(primaryNext, task: .primary, defaults: defaults)
        AppSettings.setNextDueDate(secondaryNext, task: .secondary, defaults: defaults)
        AppSettings.setWidgetDisplayTaskOption(.shortestDue, defaults: defaults)

        // When（操作）
        let selected = AppSettings.widgetDisplayTask(defaults: defaults)

        // Then（期待）
        XCTAssertEqual(selected, .secondary)
    }

    /// 対象ファイル名: HistoryRepository.swift
    /// 対象メソッド名: HistoryRepository.delete(ids:)
    ///
    /// 目的: 指定IDのみ削除し、他エントリは保持されることを保証する。
    /// Given（前提）: 3件の履歴（削除対象1件、保持対象2件）を保存する。
    /// When（操作）: 削除対象IDを指定して HistoryRepository.delete(ids:) を実行する。
    /// Then（期待）: 削除対象のみ消え、保持対象2件は残る。
    /// 回帰リスク: 履歴削除で意図しない項目まで消える。
    func testHistoryRepositoryDeleteRemovesOnlySpecifiedIDs() {
        // Given（前提）
        let backup = backupSharedStoreValues()
        defer { restoreSharedStoreValues(backup) }

        let keep1 = HistoryEntry(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            type: .done,
            task: .primary,
            itemName: "A",
            nextDueDate: Date(timeIntervalSince1970: 1_700_010_000)
        )
        let remove = HistoryEntry(
            date: Date(timeIntervalSince1970: 1_700_020_000),
            type: .skipped,
            task: .secondary,
            itemName: "B",
            nextDueDate: Date(timeIntervalSince1970: 1_700_030_000)
        )
        let keep2 = HistoryEntry(
            date: Date(timeIntervalSince1970: 1_700_040_000),
            type: .done,
            task: .primary,
            itemName: "C",
            nextDueDate: Date(timeIntervalSince1970: 1_700_050_000)
        )

        HistoryRepository.save([keep1, remove, keep2])

        // When（操作）
        HistoryRepository.delete(ids: [remove.id])

        let loaded = HistoryRepository.load()
        let loadedIDs = Set(loaded.map(\.id))

        // Then（期待）
        XCTAssertTrue(loadedIDs.contains(keep1.id))
        XCTAssertTrue(loadedIDs.contains(keep2.id))
        XCTAssertFalse(loadedIDs.contains(remove.id))
        XCTAssertEqual(loaded.count, 2)
    }

    /// 対象ファイル名: HistoryRepository.swift
    /// 対象メソッド名: HistoryRepository.updateDate(id:newDate:)
    ///
    /// 目的: 指定IDの履歴のみ日付更新し、他項目とIDを保持することを保証する。
    /// Given（前提）: 2件の履歴を保存し、片方のみ更新対象にする。
    /// When（操作）: 更新対象IDで updateDate を実行する。
    /// Then（期待）: 対象のみ日付が変わり、非対象は変わらない。
    /// 回帰リスク: 編集で別履歴が壊れる、またはIDが変化して整合性が崩れる。
    func testHistoryRepositoryUpdateDateChangesOnlyTargetEntry() {
        // Given（前提）
        let backup = backupSharedStoreValues()
        defer { restoreSharedStoreValues(backup) }

        let targetOriginalDate = Date(timeIntervalSince1970: 1_701_000_000)
        let updatedDate = Date(timeIntervalSince1970: 1_702_000_000)

        let target = HistoryEntry(
            date: targetOriginalDate,
            type: .done,
            task: .primary,
            itemName: "Target",
            nextDueDate: Date(timeIntervalSince1970: 1_701_100_000)
        )
        let untouched = HistoryEntry(
            date: Date(timeIntervalSince1970: 1_703_000_000),
            type: .skipped,
            task: .secondary,
            itemName: "Untouched",
            nextDueDate: Date(timeIntervalSince1970: 1_703_100_000)
        )

        HistoryRepository.save([target, untouched])

        // When（操作）
        HistoryRepository.updateDate(id: target.id, newDate: updatedDate)

        // Then（期待）
        let loaded = HistoryRepository.load()
        let loadedTarget = loaded.first(where: { $0.id == target.id })
        let loadedUntouched = loaded.first(where: { $0.id == untouched.id })

        XCTAssertNotNil(loadedTarget)
        XCTAssertNotNil(loadedUntouched)
        XCTAssertEqual(loadedTarget?.date, updatedDate)
        XCTAssertEqual(loadedTarget?.id, target.id)
        XCTAssertEqual(loadedTarget?.type, target.type)
        XCTAssertEqual(loadedTarget?.task, target.task)
        XCTAssertEqual(loadedTarget?.itemName, target.itemName)
        XCTAssertEqual(loadedTarget?.nextDueDate, target.nextDueDate)
        XCTAssertEqual(loadedUntouched?.date, untouched.date)
    }

    /// 対象ファイル名: WidgetDoneActionAdapter.swift
    /// 対象メソッド名: WidgetDoneActionAdapter.run()
    ///
    /// 目的: Widget経由の done がWidget表示設定に応じた task で記録されることを保証する。
    /// Given（前提）: primary/secondary に異なる設定値を保存し、表示設定を task2 にする。
    /// When（操作）: WidgetDoneActionAdapter.run() を実行する。
    /// Then（期待）: 追加される最新履歴は type=.done かつ task=.secondary になる。
    /// 回帰リスク: 表示中タスクと done 対象がずれて履歴整合性が崩れる。
    func testWidgetDoneActionAdapterRecordsTaskFromWidgetDisplaySetting() {
        // Given（前提）
        let backup = backupSharedStoreValues()
        defer { restoreSharedStoreValues(backup) }

        AppSettings.setItemName("primary-item", task: .primary)
        AppSettings.setInterval(.oneWeek, task: .primary)
        AppSettings.setItemName("secondary-item", task: .secondary)
        AppSettings.setInterval(.sixMonths, task: .secondary)
        AppSettings.setWidgetDisplayTaskOption(.task2)

        let beforeCount = HistoryRepository.load().count

        // When（操作）
        WidgetDoneActionAdapter.run()

        let histories = HistoryRepository.load()

        // Then（期待）
        XCTAssertEqual(histories.count, beforeCount + 1)

        guard let latest = histories.first else {
            XCTFail("History should have at least one entry")
            return
        }

        XCTAssertEqual(latest.type, .done)
        XCTAssertEqual(latest.task, .secondary)
        XCTAssertEqual(latest.itemName, "secondary-item")
    }

    private func backupSharedStoreValues() -> [String: Any?] {
        let defaults = SharedStore.defaults
        let keys = [
            "item", "item2",
            "intervalRawValue", "intervalRawValue2",
            "lastDoneTimestamp", "lastDoneTimestamp2",
            "nextDueTimestamp", "nextDueTimestamp2",
            "widgetDisplayTaskOption",
            SharedStore.historyKey
        ]

        var backup: [String: Any?] = [:]
        for key in keys {
            backup[key] = defaults.object(forKey: key)
        }
        return backup
    }

    private func restoreSharedStoreValues(_ backup: [String: Any?]) {
        let defaults = SharedStore.defaults
        for (key, value) in backup {
            if let value {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
