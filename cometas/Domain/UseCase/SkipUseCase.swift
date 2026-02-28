//
//  SkipUseCase.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

struct SkipUseCase {
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
    func execute(baseDate: Date? = nil) -> HistoryEntry {
        let itemName = settings.itemName
        let interval = settings.interval
        let skippedDate = baseDate ?? settings.nextDueDate
        let nextDueDate = calculator.calculate(from: skippedDate, interval: interval)

        settings.setNextDueDate(nextDueDate)

        let entry = HistoryEntry(
            date: skippedDate,
            type: .skipped,
            task: settings.task,
            itemName: itemName,
            nextDueDate: nextDueDate
        )

        historyWriter.append(entry)
        widgetReloader.reload()

        return entry
    }
}
