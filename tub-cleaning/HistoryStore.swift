//
//  HistoryStore.swift
//  tub-cleaning
//
//  Created by 西岡宰 on 2026/01/24.
//

import Foundation

import SwiftUI
import Combine

final class HistoryStore: ObservableObject {

    // UserDefaults に保存される実体
    @AppStorage("historyData") private var historyData: Data = Data()

    // 画面で使う履歴
    @Published private(set) var histories: [HistoryEntry] = []

    private let key = "historyEntries"

    init() {
        load()
    }

    // MARK: - 追加
    func add(type: HistoryType, date: Date, itemName: String) {
        histories.insert(
            HistoryEntry(date: date, type: type, itemName: itemName),
            at: 0
        )
        save()
    }

    // MARK: - 保存
    private func save() {
        guard let data = try? JSONEncoder().encode(histories) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    func delete(at offsets: IndexSet) {
        histories.remove(atOffsets: offsets)
        save()
    }
    // MARK: - 読み込み
    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else { return }

        histories = decoded
    }
}
