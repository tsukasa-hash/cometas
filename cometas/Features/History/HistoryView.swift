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

    private let paper = Color(red: 243 / 255, green: 241 / 255, blue: 234 / 255)
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
                            Button {
                                editedDate = entry.date
                                withAnimation(.easeOut(duration: 0.25)) {
                                    editingEntry = entry
                                }
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: entry.type == .done ? "checkmark" : "arrow.uturn.backward")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(sage)
                                        .frame(width: 32, height: 32)
                                        .background(sageSoft, in: Circle())

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(entry.itemName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(ink)
                                        Text(DatePresentation.yearMonthDayWithoutPadding(entry.date))
                                            .font(.system(size: 11))
                                            .foregroundStyle(muted)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(muted.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                                .padding(.horizontal, 16)
                                .background(card)
                                .overlay(alignment: .bottom) {
                                    if index < filteredHistories.count - 1 {
                                        Rectangle().fill(line).frame(height: 1).padding(.leading, 59)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(card)
                            .listRowSeparator(.hidden)
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
            editSheet(for: entry)
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
            .presentationBackground(paper)
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


    private func editSheet(for entry: HistoryEntry) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button("キャンセル") {
                    editingEntry = nil
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(muted)

                Spacer()
                Text("履歴を編集")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ink)
                Spacer()

                Button {
                    historyStore.updateDate(id: entry.id, newDate: editedDate)
                    editingEntry = nil
                } label: {
                    Text("保存")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(sage)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(sageSoft, in: Capsule())
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
            .padding(.top, 30)

            Rectangle()
                .fill(line)
                .frame(height: 1)
                .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: entry.type == .done ? "checkmark" : "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(sage)
                        .frame(width: 28, height: 28)
                        .background(sageSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.type == .done ? "完了したタスク" : "スキップしたタスク")
                            .font(.system(size: 10))
                            .foregroundStyle(muted)
                        Text(entry.itemName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ink)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 68)
                .background(card, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(line.opacity(0.7), lineWidth: 1))

                HStack(spacing: 8) {
                    quickDateButton(title: "2日前", date: twoDaysAgoDate)
                    quickDateButton(title: "昨日", date: yesterdayDate)
                    quickDateButton(title: "今日", date: todayDate)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("実施日")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(muted)
                    DatePicker("実施日", selection: $editedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .labelsHidden()
                        .tint(ink)
                        .frame(maxWidth: .infinity)
                }

                Text("選択した日付で履歴を更新します。")
                    .font(.system(size: 13))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            Spacer(minLength: 0)
        }
        .background(paper)
    }

    private func quickDateButton(title: String, date: Date) -> some View {
        let isSelected = calendar.isDate(editedDate, inSameDayAs: date)
        return Button {
            editedDate = date
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? sage : muted)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(isSelected ? sageSoft : paper, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? sage.opacity(0.25) : line, lineWidth: 1))
        }
        .buttonStyle(.plain)
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
