//
//  SharedLogic.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation
import WidgetKit

enum DoneAction {

    static func done() {
        let defaults = SharedStore.defaults
        let now = Date()

//      項目名が設定されていなければ空白を表示する
        let item = defaults.string(forKey: "item") ?? ""

        // 日付更新
        defaults.set(now.timeIntervalSince1970, forKey: "lastDoneTimestamp")

        
        let intervalRaw = defaults.string(forKey: "intervalRawValue") ?? "twoMonths"
        let interval = Interval(rawValue: intervalRaw) ?? .twoMonths

        let next = Calendar.current.date(
            byAdding: interval.dateComponent,
            to: now
        ) ?? now

        defaults.set(next.timeIntervalSince1970, forKey: "nextDueTimestamp")

        // 履歴追加
        let entry = HistoryEntry(
            date: now,
            type: .done,
            itemName: item,
            nextDueDate: next
        )

        HistoryRepository.append(entry)

        // ウィジェット更新
        WidgetCenter.shared.reloadTimelines(
            ofKind: "cometasWidget"
        )
    }
}
