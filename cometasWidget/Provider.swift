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
        let defaults = SharedStore.defaults

        let itemName = defaults.string(forKey: "item") ?? "未設定"
        
        let nextDueTs = defaults.double(forKey: "nextDueTimestamp")
        let nextDueDate = Date(timeIntervalSince1970: nextDueTs == 0 ? Date().timeIntervalSince1970 : nextDueTs)
        completion(SimpleEntry(date: Date(), itemName: itemName, nextDueDate: nextDueDate))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SimpleEntry>) -> Void
    ) {
        let defaults = SharedStore.defaults

        let itemName = defaults.string(forKey: "item") ?? "未設定"
        let nextDueTs = defaults.double(forKey: "nextDueTimestamp")
        let nextDueDate = Date(timeIntervalSince1970: nextDueTs == 0 ? Date().timeIntervalSince1970 : nextDueTs)
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
