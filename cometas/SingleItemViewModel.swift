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

    private let recordDoneUseCase: RecordDoneUseCase
    private let skipUseCase: SkipUseCase
    private let widgetReloader: WidgetTimelineReloading

    init(
        recordDoneUseCase: RecordDoneUseCase = RecordDoneUseCase(),
        skipUseCase: SkipUseCase = SkipUseCase(),
        widgetReloader: WidgetTimelineReloading = WidgetCenterTimelineReloader()
    ) {
        self.recordDoneUseCase = recordDoneUseCase
        self.skipUseCase = skipUseCase
        self.widgetReloader = widgetReloader
    }

    func reloadFromSettings() {
        item = AppSettings.itemName()
        interval = AppSettings.interval()
        lastDoneDate = AppSettings.lastDoneDate()
        nextDueDate = AppSettings.nextDueDate()
    }

    func setItem(_ item: String) {
        self.item = item
        AppSettings.setItemName(item)
        widgetReloader.reload()
    }

    func setInterval(_ interval: Interval) {
        self.interval = interval
        AppSettings.setInterval(interval)
        recalculateFromLastDone()
    }

    func setLastDoneDate(_ date: Date) {
        lastDoneDate = date
        AppSettings.setLastDoneDate(date)
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
        AppSettings.setNextDueDate(recalculated)
        widgetReloader.reload()
    }
}
