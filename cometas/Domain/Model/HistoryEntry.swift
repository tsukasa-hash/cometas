//
//  HistoryEntry.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

enum ManagedTask: Int, Codable, CaseIterable, Identifiable {
    case primary = 1
    case secondary = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .primary:
            return "task1"
        case .secondary:
            return "task2"
        }
    }
}

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
    let task: ManagedTask
    let itemName: String
    let nextDueDate: Date

    init(
        id: UUID = UUID(),
        date: Date,
        type: HistoryType,
        task: ManagedTask,
        itemName: String,
        nextDueDate: Date
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.task = task
        self.itemName = itemName
        self.nextDueDate = nextDueDate
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case type
        case task
        case itemName
        case nextDueDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        type = try container.decode(HistoryType.self, forKey: .type)
        task = try container.decodeIfPresent(ManagedTask.self, forKey: .task) ?? .primary
        itemName = try container.decode(String.self, forKey: .itemName)
        nextDueDate = try container.decode(Date.self, forKey: .nextDueDate)
    }
}
