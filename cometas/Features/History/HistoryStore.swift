//
//  HistoryStore.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

import SwiftUI
import Combine

final class HistoryStore: ObservableObject {
//アプリからの永続化はこのクラスを経由する

    // 画面で使う履歴
    @Published private(set) var histories: [HistoryEntry] = []

    init() {
        reload()
    }
    
    // MARK: - 読み込み
    func reload() {
        histories = HistoryRepository.load()
    }
    
    // MARK: - 追加
    func add(type: HistoryType, task: ManagedTask, date: Date, itemName: String, nextDueDate: Date) {
        let entry = HistoryEntry(
            date: date,
            type: type,
            task: task,
            itemName: itemName,
            nextDueDate: nextDueDate
        )
        histories.insert(entry, at: 0)
        HistoryRepository.append(entry)
    }

    // MARK: - 追加（永続化済み）
    func insertPersisted(_ entry: HistoryEntry) {
        histories.insert(entry, at: 0)
    }

    // MARK: - 削除
    func delete(ids: [UUID]) {
        guard !ids.isEmpty else { return }

        let idSet = Set(ids)
        histories.removeAll { idSet.contains($0.id) }
        HistoryRepository.delete(ids: ids)
    }

    // MARK: - 日付更新
    func updateDate(id: UUID, newDate: Date) {
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
        HistoryRepository.updateDate(id: id, newDate: newDate)
    }
}
