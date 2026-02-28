//
//  HistoryView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

import SwiftUI

private enum HistoryTaskFilter: String, CaseIterable, Identifiable {
    case all
    case primary
    case secondary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "全て"
        case .primary:
            return "task1"
        case .secondary:
            return "task2"
        }
    }

    func includes(_ task: ManagedTask) -> Bool {
        switch self {
        case .all:
            return true
        case .primary:
            return task == .primary
        case .secondary:
            return task == .secondary
        }
    }
}

private enum HistoryPeriodFilter: String, CaseIterable, Identifiable {
    case all
    case sevenDays
    case thirtyDays
    case ninetyDays

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "全期間"
        case .sevenDays:
            return "7日"
        case .thirtyDays:
            return "30日"
        case .ninetyDays:
            return "90日"
        }
    }

    func includes(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch self {
        case .all:
            return true
        case .sevenDays:
            return date >= (calendar.date(byAdding: .day, value: -7, to: now) ?? .distantPast)
        case .thirtyDays:
            return date >= (calendar.date(byAdding: .day, value: -30, to: now) ?? .distantPast)
        case .ninetyDays:
            return date >= (calendar.date(byAdding: .day, value: -90, to: now) ?? .distantPast)
        }
    }
}

struct HistoryView: View {
    
    @EnvironmentObject var historyStore: HistoryStore
    @State private var selectedTaskFilter: HistoryTaskFilter = .all
    @State private var selectedPeriodFilter: HistoryPeriodFilter = .all

    private var filteredHistories: [HistoryEntry] {
        historyStore.histories.filter { entry in
            selectedTaskFilter.includes(entry.task) && selectedPeriodFilter.includes(entry.date)
        }
    }
    
    var body: some View {
        List {
//            Section {
//                HStack {
//                    Spacer()
//                    taskFilterMenu
//                }
//            }
//
//            Section("期間") {
//                Picker("期間", selection: $selectedPeriodFilter) {
//                    ForEach(HistoryPeriodFilter.allCases) { filter in
//                        Text(filter.label).tag(filter)
//                    }
//                }
//                .pickerStyle(.menu)
//            }
            Section("履歴") {
                ForEach(filteredHistories) { entry in
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
                            Text(entry.date, format: DatePresentation.ymdFormat)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { filteredHistories[$0].id }
                    historyStore.delete(ids: ids)
                }
                
            }
        }
    }

    private var taskFilterMenu: some View {
        Menu {
            ForEach(HistoryTaskFilter.allCases) { filter in
                Button {
                    selectedTaskFilter = filter
                } label: {
                    if selectedTaskFilter == filter {
                        Label(filter.label, systemImage: "checkmark")
                    } else {
                        Text(filter.label)
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 56, height: 56)
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
