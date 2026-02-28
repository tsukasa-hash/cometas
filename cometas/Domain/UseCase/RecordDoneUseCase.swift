//
//  RecordDoneUseCase.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

protocol AppSettingsAccessing {
    var task: ManagedTask { get }
    var itemName: String { get }
    var interval: Interval { get }
    var nextDueDate: Date { get }
    func setLastDoneDate(_ date: Date)
    func setNextDueDate(_ date: Date)
}

struct UserDefaultsAppSettingsStore: AppSettingsAccessing {
    let task: ManagedTask

    init(task: ManagedTask = .primary) {
        self.task = task
    }

    var itemName: String { AppSettings.itemName(task: task) }
    var interval: Interval { AppSettings.interval(task: task) }
    var nextDueDate: Date { AppSettings.nextDueDate(task: task) }

    func setLastDoneDate(_ date: Date) {
        AppSettings.setLastDoneDate(date, task: task)
    }

    func setNextDueDate(_ date: Date) {
        AppSettings.setNextDueDate(date, task: task)
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
            task: settings.task,
            itemName: itemName,
            nextDueDate: nextDueDate
        )

        historyWriter.append(entry)
        widgetReloader.reload()

        return entry
    }
}
