//
//  Provider.swift
//  tub-cleaningWidgetExtension
//
//  Created by ChatGPT on 2026/01/24.
//

import WidgetKit

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), itemName: "項目名")
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SimpleEntry) -> Void
    ) {
        let defaults = SharedStore.defaults

        let itemName = defaults.string(forKey: "item") ?? "未設定"
        completion(SimpleEntry(date: Date(), itemName: itemName))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<SimpleEntry>) -> Void
    ) {
        let defaults = SharedStore.defaults

        let itemName = defaults.string(forKey: "item") ?? "未設定"
        let entry = SimpleEntry(date: Date(), itemName: itemName)
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
}
