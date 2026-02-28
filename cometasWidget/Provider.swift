//
//  Provider.swift
//  cometasWidgetExtension
//
//  Created by ChatGPT on 2026/01/24.
//

import WidgetKit

struct Provider: TimelineProvider {

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
        let entry = SimpleEntry(date: Date(), itemName: itemName, nextDueDate: nextDueDate)
        let timeline = Timeline(
            entries: [entry],
            policy: .never
        )
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let itemName: String
    let nextDueDate: Date
}
