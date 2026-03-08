//
//  Provider.swift
//  cometasWidgetExtension
//
//  Created by ChatGPT on 2026/01/24.
//

import WidgetKit

struct Provider: TimelineProvider {
    private var calendar: Calendar { .autoupdatingCurrent }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), itemName: "項目名", nextDueDate: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SimpleEntry) -> Void
    ) {
        let storedItemName = AppSettings.itemName()
        let itemName = storedItemName.isEmpty ? "未設定" : storedItemName
        let nextDueDate = AppSettings.nextDueDate()
        completion(SimpleEntry(date: Date(), itemName: itemName, nextDueDate: nextDueDate))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SimpleEntry>) -> Void
    ) {
        let storedItemName = AppSettings.itemName()
        let itemName = storedItemName.isEmpty ? "未設定" : storedItemName
        let nextDueDate = AppSettings.nextDueDate()
        let now = Date()
        let entry = SimpleEntry(date: now, itemName: itemName, nextDueDate: nextDueDate)
        let nextRefresh = nextDayBoundary(from: now)
        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextRefresh)
        )
        completion(timeline)
    }

    private func nextDayBoundary(from date: Date) -> Date {
        let startOfToday = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(60 * 60 * 24)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let itemName: String
    let nextDueDate: Date
}
