//
//  HistoryEntry.swift
//  tub-cleaning
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

enum HistoryType: String, Codable {
    case done
    case skipped

    var label: String {
        switch self {
        case .done:
            return "やった"
        case .skipped:
            return "スキップ"
        }
    }

    var systemImage: String {
        switch self {
        case .done:
            return "checkmark.circle.fill"
        case .skipped:
            return "forward.end.circle"
        }
    }
}

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: HistoryType
    let itemName: String

    init(date: Date, type: HistoryType, itemName: String) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.itemName = itemName
    }
}
