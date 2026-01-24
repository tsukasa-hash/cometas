//
//  HistoryView.swift
//  tub-cleaning
//
//  Created by 西岡宰 on 2026/01/24.
//

import Foundation

import SwiftUI

struct HistoryView: View {
    
    @EnvironmentObject var historyStore: HistoryStore
    @State private var showDeleteConfirm = false
    @State private var pendingDeleteOffsets: IndexSet?
    
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()
    
    var body: some View {
        List {
            ForEach(historyStore.histories) { entry in
                HStack {
                    Image(systemName: entry.type.systemImage)
                        .foregroundStyle(entry.type == .done ? .green : .orange)

                    VStack(alignment: .leading) {
                        HStack {
                            
                            Text(entry.type.label)
                                .font(.headline)
                            Text(entry.itemName)
                                .font(.headline)

                        }
                        Text(formatter.string(from: entry.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                pendingDeleteOffsets = offsets
                showDeleteConfirm = true
            }
        }
        
        .confirmationDialog(
            "この履歴を削除しますか？",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let offsets = pendingDeleteOffsets {
                    historyStore.delete(at: offsets)
                    pendingDeleteOffsets = nil
                }
            }
//            iOSの仕様か、キャンセルボタンは表示されない
            Button("キャンセル", role: .cancel) {
                pendingDeleteOffsets = nil
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        historyStore.delete(at: offsets)
    }
}
