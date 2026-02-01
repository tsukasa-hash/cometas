//
//  HistoryRepository.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation
import SwiftUI

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
    
    
    static func delete(at offsets: IndexSet) {
        var histories = load()
        histories.remove(atOffsets: offsets)
        save(histories)
    }
}
