//
//  HistoryRepository.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

enum HistoryRepository {
//    アプリ、ウィジェットいずれも永続化はこのクラスを使う

    static func load() -> [HistoryEntry] {
        let defaults = SharedStore.defaults

        guard
            let data = defaults.data(forKey: SharedStore.historyKey),
            let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else {
            return []
        }

        return decoded
    }

    static func save(_ histories: [HistoryEntry]) {
        let defaults = SharedStore.defaults
        guard let data = try? JSONEncoder().encode(histories) else { return }
        defaults.set(data, forKey: SharedStore.historyKey)
    }

    static func append(_ entry: HistoryEntry) {
        var histories = load()
        histories.insert(entry, at: 0)
        save(histories)
    }

    static func delete(ids: [UUID]) {
        guard !ids.isEmpty else { return }

        var histories = load()
        let idSet = Set(ids)
        histories.removeAll { idSet.contains($0.id) }
        save(histories)
    }

    static func updateDate(id: UUID, newDate: Date) {
        var histories = load()
        guard let index = histories.firstIndex(where: { $0.id == id }) else { return }

        let current = histories[index]
        histories[index] = HistoryEntry(
            id: current.id,
            date: newDate,
            type: current.type,
            task: current.task,
            itemName: current.itemName,
            nextDueDate: current.nextDueDate
        )
        save(histories)
    }
}
