//
//  RecordDoneUseCase.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

protocol AppSettingsAccessing {
    var itemName: String { get }
    var interval: Interval { get }
    var nextDueDate: Date { get }
    func setLastDoneDate(_ date: Date)
    func setNextDueDate(_ date: Date)
}

struct UserDefaultsAppSettingsStore: AppSettingsAccessing {
    var itemName: String { AppSettings.itemName() }
    var interval: Interval { AppSettings.interval() }
    var nextDueDate: Date { AppSettings.nextDueDate() }

    func setLastDoneDate(_ date: Date) {
        AppSettings.setLastDoneDate(date)
    }

    func setNextDueDate(_ date: Date) {
        AppSettings.setNextDueDate(date)
    }
}

protocol HistoryEntryWriting {
    func append(_ entry: HistoryEntry)
}

struct UserDefaultsHistoryEntryWriter: HistoryEntryWriting {
    func append(_ entry: HistoryEntry) {
        HistoryRepository.append(entry)
    }
}

protocol NextDueDateCalculating {
    func calculate(from baseDate: Date, interval: Interval) -> Date
}

struct DefaultNextDueDateCalculator: NextDueDateCalculating {
    func calculate(from baseDate: Date, interval: Interval) -> Date {
        NextDueDateCalculator.calculate(from: baseDate, interval: interval)
    }
}

struct RecordDoneUseCase {
    private let settings: AppSettingsAccessing
    private let historyWriter: HistoryEntryWriting
    private let calculator: NextDueDateCalculating
    private let widgetReloader: WidgetTimelineReloading

    init(
        settings: AppSettingsAccessing = UserDefaultsAppSettingsStore(),
        historyWriter: HistoryEntryWriting = UserDefaultsHistoryEntryWriter(),
        calculator: NextDueDateCalculating = DefaultNextDueDateCalculator(),
        widgetReloader: WidgetTimelineReloading = WidgetCenterTimelineReloader()
    ) {
        self.settings = settings
        self.historyWriter = historyWriter
        self.calculator = calculator
        self.widgetReloader = widgetReloader
    }

    @discardableResult
    func execute(at now: Date = Date()) -> HistoryEntry {
        let itemName = settings.itemName
        let interval = settings.interval

        settings.setLastDoneDate(now)

        let nextDueDate = calculator.calculate(from: now, interval: interval)
        settings.setNextDueDate(nextDueDate)

        let entry = HistoryEntry(
            date: now,
            type: .done,
            itemName: itemName,
            nextDueDate: nextDueDate
        )

        historyWriter.append(entry)
        widgetReloader.reload()

        return entry
    }
}
