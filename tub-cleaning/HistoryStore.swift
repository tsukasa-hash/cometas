//
//  HistoryStore.swift
//  tub-cleaning
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
    func add(type: HistoryType, date: Date, itemName: String, nextDueDate: Date) {
        let entry = HistoryEntry(
                    date: date,
                    type: type,
                    itemName: itemName,
                    nextDueDate: nextDueDate
                )
                HistoryRepository.append(entry)
                reload()
        
    }

    // MARK: - 削除
    func delete(at offsets: IndexSet) {
        
        HistoryRepository.delete(at: offsets)
        reload()
    }
}
