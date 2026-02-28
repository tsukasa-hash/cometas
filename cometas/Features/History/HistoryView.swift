//
//  HistoryView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

import SwiftUI

struct HistoryView: View {
    
    @EnvironmentObject var historyStore: HistoryStore

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
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { historyStore.histories[$0].id }
                historyStore.delete(ids: ids)
            }
        }
    }
}
