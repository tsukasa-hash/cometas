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
    @Environment(\.calendar) private var calendar
    @State private var selectedTaskFilter: HistoryTaskFilter = .all
    @State private var selectedPeriodFilter: HistoryPeriodFilter = .all
    @State private var editingEntry: HistoryEntry?
    @State private var editedDate: Date = Date()
    @State private var pressingEntryID: UUID?

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
                    .listRowBackground(
                        (pressingEntryID == entry.id) ? Color(uiColor: .systemGray5) : Color.clear
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            historyStore.delete(ids: [entry.id])
                        } label: {
                            Label("削除", systemImage: "trash")
                        }

                        Button {
                            editingEntry = entry
                            editedDate = entry.date
                        } label: {
                            Label("編集", systemImage: "pencil.line")
                        }
                        .tint(.orange)
                    }
                    .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                        pressingEntryID = isPressing ? entry.id : nil
                    }) {
                        editingEntry = entry
                        editedDate = entry.date
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { filteredHistories[$0].id }
                    historyStore.delete(ids: ids)
                }
                
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        quickDateButton(title: "2日前", date: twoDaysAgoDate)
                        quickDateButton(title: "昨日", date: yesterdayDate)
                    }
                    DatePicker(
                        "やった日付",
                        selection: $editedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .labelsHidden()
                }
                .navigationTitle("履歴を編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            editingEntry = nil
                        }
                        .buttonStyle(.plain)
                        .frame(width: 100, alignment: .center)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            historyStore.updateDate(id: entry.id, newDate: editedDate)
                            editingEntry = nil
                        }
                        .buttonStyle(DefaultButtonStyle())
                        .frame(width: 100, alignment: .center)
                        .foregroundStyle(Color.blue)
                    }
                }
            }
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
        }
    }

    private var todayDate: Date {
        calendar.startOfDay(for: Date())
    }

    private var yesterdayDate: Date {
        calendar.date(byAdding: .day, value: -1, to: todayDate) ?? todayDate
    }

    private var twoDaysAgoDate: Date {
        calendar.date(byAdding: .day, value: -2, to: todayDate) ?? todayDate
    }


    private func quickDateButton(title: String, date: Date) -> some View {
        let isSelected = calendar.isDate(editedDate, inSameDayAs: date)
        return Group {
            if isSelected {
                Button {
                    editedDate = date
                }
                label: {
                        Text(title)
                        .font(.headline)
                        .listRowBackground(Color.clear)
                        .foregroundColor(.white)
                        .frame(maxWidth: 150, minHeight: 30)
                        .background(.black)
                        .cornerRadius(30)
                }
//                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    editedDate = date
                }
                label: {
                        Text(title)
                            .font(.headline)
                            .listRowBackground(Color.clear)
                            .foregroundColor(.gray)
                            .frame(maxWidth: 150, minHeight: 30)
                            .background(.white)
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(maxWidth: 150, minHeight: 30)
                            )
                }
//                .buttonStyle(.bordered)
            }
        }
        .tint(.black)
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
