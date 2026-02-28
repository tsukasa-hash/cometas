//
//  SingleItemViewModel.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation
import Combine

final class SingleItemViewModel: ObservableObject {
    @Published var item: String = ""
    @Published var interval: Interval = AppSettings.defaultInterval
    @Published var lastDoneDate: Date = Date()
    @Published var nextDueDate: Date = Date()

    let task: ManagedTask
    private let recordDoneUseCase: RecordDoneUseCase
    private let skipUseCase: SkipUseCase
    private let widgetReloader: WidgetTimelineReloading

    init(task: ManagedTask = .primary) {
        self.task = task
        let settings = UserDefaultsAppSettingsStore(task: task)
        let historyWriter = UserDefaultsHistoryEntryWriter()
        let calculator = DefaultNextDueDateCalculator()
        let widgetReloader: WidgetTimelineReloading = task == .primary
            ? WidgetCenterTimelineReloader()
            : NoopWidgetTimelineReloader()

        self.recordDoneUseCase = RecordDoneUseCase(
            settings: settings,
            historyWriter: historyWriter,
            calculator: calculator,
            widgetReloader: widgetReloader
        )
        self.skipUseCase = SkipUseCase(
            settings: settings,
            historyWriter: historyWriter,
            calculator: calculator,
            widgetReloader: widgetReloader
        )
        self.widgetReloader = widgetReloader
    }

    func reloadFromSettings() {
        item = AppSettings.itemName(task: task)
        interval = AppSettings.interval(task: task)
        lastDoneDate = AppSettings.lastDoneDate(task: task)
        nextDueDate = AppSettings.nextDueDate(task: task)
    }

    func setItem(_ item: String) {
        self.item = item
        AppSettings.setItemName(item, task: task)
        widgetReloader.reload()
    }

    func setInterval(_ interval: Interval) {
        self.interval = interval
        AppSettings.setInterval(interval, task: task)
        recalculateFromLastDone()
    }

    func setLastDoneDate(_ date: Date) {
        lastDoneDate = date
        AppSettings.setLastDoneDate(date, task: task)
        recalculateFromLastDone()
    }

    func handleDone(historyStore: HistoryStore) {
        let entry = recordDoneUseCase.execute()
        historyStore.insertPersisted(entry)
        reloadFromSettings()
    }

    func handleSkip(historyStore: HistoryStore) {
        let entry = skipUseCase.execute(baseDate: nextDueDate)
        historyStore.insertPersisted(entry)
        reloadFromSettings()
    }

    private func recalculateFromLastDone() {
        let recalculated = NextDueDateCalculator.calculate(from: lastDoneDate, interval: interval)
        nextDueDate = recalculated
        AppSettings.setNextDueDate(recalculated, task: task)
        widgetReloader.reload()
    }
}
