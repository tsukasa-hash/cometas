//
//  HistoryView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

import SwiftUI

private struct HistoryRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private enum HistoryTypeSelection: String, CaseIterable, Identifiable {
    case all
    case done
    case skipped

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "すべて"
        case .done:
            return "やった"
        case .skipped:
            return "スキップ"
        }
    }

    func includes(_ type: HistoryType) -> Bool {
        switch self {
        case .all:
            return true
        case .done:
            return type == .done
        case .skipped:
            return type == .skipped
        }
    }
}

private enum HistoryTaskSelection: String, CaseIterable, Identifiable {
    case all
    case task1
    case task2

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "すべて"
        case .task1:
            return "タスク1"
        case .task2:
            return "タスク2"
        }
    }

    func includes(_ task: ManagedTask) -> Bool {
        switch self {
        case .all:
            return true
        case .task1:
            return task == .primary
        case .task2:
            return task == .secondary
        }
    }
}

struct HistoryView: View {
    var onBackgroundSwipeLeft: () -> Void = {}

    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.calendar) private var calendar
    @State private var selectedType: HistoryTypeSelection = .all
    @State private var selectedTask: HistoryTaskSelection = .all
    @State private var editingEntry: HistoryEntry?
    @State private var editedDate: Date = Date()
    @State private var pressingEntryID: UUID?
    @State private var rowFrames: [UUID: CGRect] = [:]
    private let minSwipeDistance: CGFloat = 60

    private var filteredHistories: [HistoryEntry] {
        historyStore.histories.filter { entry in
            selectedType.includes(entry.type) && selectedTask.includes(entry.task)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
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
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: HistoryRowFramePreferenceKey.self,
                                value: [entry.id: proxy.frame(in: .named("historyList"))]
                            )
                        }
                    )
                }
                .onDelete { offsets in
                    let ids = offsets.map { filteredHistories[$0].id }
                    historyStore.delete(ids: ids)
                }
            }
            .coordinateSpace(name: "historyList")
            .listStyle(.plain)
            .scrollIndicators(.visible)
            .simultaneousGesture(backgroundLeftSwipeGesture())
            .onPreferenceChange(HistoryRowFramePreferenceKey.self) { frames in
                rowFrames = frames
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
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

    private func backgroundLeftSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .named("historyList"))
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                guard abs(horizontal) > abs(vertical), horizontal < -minSwipeDistance else {
                    return
                }

                guard !isSwipeStartedOnRow(value.startLocation) else {
                    return
                }

                onBackgroundSwipeLeft()
            }
    }

    private func isSwipeStartedOnRow(_ startLocation: CGPoint) -> Bool {
        rowFrames.values.contains { frame in
            (frame.minY ... frame.maxY).contains(startLocation.y)
        }
    }

    private var filterMenu: some View {
        Menu {
            Section("種類") {
                ForEach(HistoryTypeSelection.allCases) { filter in
                    Button {
                        selectedType = filter
                    } label: {
                        filterLabel(filter.label, isSelected: selectedType == filter)
                    }
                }
            }

            Section("タスク") {
                ForEach(HistoryTaskSelection.allCases) { filter in
                    Button {
                        selectedTask = filter
                    } label: {
                        filterLabel(filter.label, isSelected: selectedTask == filter)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.plain)
    }

    private func filterLabel(_ title: String, isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }
}
