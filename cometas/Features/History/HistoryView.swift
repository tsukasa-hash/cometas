//
//  HistoryView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

import SwiftUI

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

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.calendar) private var calendar
    @State private var selectedType: HistoryTypeSelection = .all
    @State private var selectedTask: ManagedTask?
    @State private var editingEntry: HistoryEntry?
    @State private var editedDate: Date = Date()
    @State private var pressingEntryID: UUID?

    private let paper = Color(red: 245 / 255, green: 243 / 255, blue: 237 / 255)
    private let card = Color(red: 251 / 255, green: 250 / 255, blue: 246 / 255)
    private let ink = Color(red: 41 / 255, green: 45 / 255, blue: 43 / 255)
    private let muted = Color(red: 134 / 255, green: 137 / 255, blue: 130 / 255)
    private let sage = Color(red: 104 / 255, green: 123 / 255, blue: 107 / 255)
    private let sageSoft = Color(red: 223 / 255, green: 229 / 255, blue: 220 / 255)
    private let line = Color(red: 226 / 255, green: 224 / 255, blue: 217 / 255)

    private var filteredHistories: [HistoryEntry] {
        historyStore.histories.filter { entry in
            selectedType.includes(entry.type) && (selectedTask == nil || selectedTask == entry.task)
        }
    }

    private var availableTasks: [ManagedTask] {
        Array(Set(historyStore.histories.map(\.task))).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if filteredHistories.isEmpty {
                        Text("記録はまだありません。")
                            .font(.system(size: 13))
                            .foregroundStyle(muted)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .listRowBackground(card)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(filteredHistories.enumerated()), id: \.element.id) { index, entry in
                            HStack(spacing: 13) {
                                if entry.type == .done {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(sage)
                                        .frame(width: 30, height: 30)
                                        .background(sageSoft, in: Circle())
                                } else {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(sage)
                                        .frame(width: 30, height: 30)
                                        .background(sageSoft, in: Circle())
                                }

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(entry.itemName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(ink)
                                    Text(DatePresentation.yearMonthDayWithoutPadding(entry.date))
                                        .font(.system(size: 11))
                                        .foregroundStyle(muted)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 72)
                            .padding(.horizontal, 16)
                            .background(pressingEntryID == entry.id ? sageSoft.opacity(0.55) : card)
                            .overlay(alignment: .bottom) {
                                if index < filteredHistories.count - 1 {
                                    Rectangle().fill(line).frame(height: 1).padding(.leading, 59)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(paper)
                            .listRowSeparator(.hidden)
                            .listRowBackground(card)
                            .contentShape(Rectangle())
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
                    }
                } header: {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("cometas")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .tracking(0.7)
                                .foregroundStyle(sage)
                            Text("これまでの記録")
                                .font(.system(size: 29, weight: .bold))
                                .tracking(-0.8)
                                .foregroundStyle(ink)
                        }
                        Spacer()
                        filterMenu
                    }
                    .textCase(nil)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(paper.ignoresSafeArea())
            .scrollIndicators(.visible)
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(sage)
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
                Button {
                    selectedTask = nil
                } label: {
                    filterLabel("すべて", isSelected: selectedTask == nil)
                }

                ForEach(availableTasks) { task in
                    Button {
                        selectedTask = task
                    } label: {
                        filterLabel(taskDisplayName(task), isSelected: selectedTask == task)
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

    private func taskDisplayName(_ task: ManagedTask) -> String {
        historyStore.histories.first(where: { $0.task == task })?.itemName.nonEmpty ?? task.label
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
