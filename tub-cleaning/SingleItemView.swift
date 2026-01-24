//
//  SingleItemView.swift
//  tub-cleaning
//
//  Created by ChatGPT on 2026/01/18.
//

import Foundation

import SwiftUI

struct SingleItemView: View {
    
    // MARK: - AppStorage（保存用）
    @AppStorage("item")
    private var item: String = ""

    @AppStorage("intervalRawValue")
    private var intervalRawValue: String = Interval.twoMonths.rawValue

    @AppStorage("lastDoneTimestamp")
    private var lastDoneTimestamp: Double = Date().timeIntervalSince1970

    @AppStorage("nextDueTimestamp")
    private var nextDueTimestamp: Double = Date().timeIntervalSince1970

    @EnvironmentObject var historyStore: HistoryStore


    // MARK: - UI用 Binding（変換だけ）

    private var interval: Binding<Interval> {
        Binding(
            get: { Interval(rawValue: intervalRawValue) ?? .twoMonths },
            set: { intervalRawValue = $0.rawValue }
        )
    }

    private var lastDoneDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: lastDoneTimestamp) },
            set: { lastDoneTimestamp = $0.timeIntervalSince1970 }
        )
    }

    private var nextDueDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: nextDueTimestamp) },
            set: { nextDueTimestamp = $0.timeIntervalSince1970 }
        )
    }

    // MARK: - Logic

    private func calculateNext(from base: Date) -> Date {
        Calendar.current.date(
            byAdding: interval.wrappedValue.dateComponent,
            to: base
        ) ?? base
    }

    private func recalcFromLastDone() {
        nextDueDate.wrappedValue = calculateNext(from: lastDoneDate.wrappedValue)
    }

    // MARK: - View

    var body: some View {
        Form {
            Section("項目") {
                TextField("項目名", text: $item)
            }
            Section("間隔") {
                Picker("", selection: interval) {
                    ForEach(Interval.allCases) {
                        Text($0.label).tag($0)
                    }
                }
            }

            Section("日付") {
                DatePicker("前回", selection: lastDoneDate, displayedComponents: .date)
                DatePicker("次回", selection: nextDueDate, displayedComponents: .date)
                    .disabled(true)
            }

            Section {
                Button("やった") {
                    handleDone()
                }

                Button("今回はやらない") {
                    handleSkip()
                }
            }
        }
        .onChange(of: interval.wrappedValue) {
            recalcFromLastDone()
        }
        .onChange(of: lastDoneDate.wrappedValue) {
            recalcFromLastDone()
        }
    }

    // MARK: - Actions

    private func handleDone() {
        let today = Date()
        lastDoneDate.wrappedValue = today
        nextDueDate.wrappedValue = calculateNext(from: today)
        historyStore.add(type: .done, date: today, itemName: item)
    }

    private func handleSkip() {
        let base = nextDueDate.wrappedValue
        nextDueDate.wrappedValue = calculateNext(from: base)
        
        let skippedDate = base
        historyStore.add(type: .skipped, date: skippedDate, itemName: item)
    }
}

// MARK: - Interval

enum Interval: String, CaseIterable, Identifiable {
    case tenDays
    case oneWeek
    case oneMonth
    case twoMonths
    case sixMonths

    var id: Self { self }

    var label: String {
        switch self {
        case .oneWeek:
            return "1週間"
        case .tenDays:
            return "10日"
        case .oneMonth:
            return "1ヶ月"
        case .twoMonths:
            return "2ヶ月"
        case .sixMonths:
            return "6ヶ月"
        }
    }

    var dateComponent: DateComponents {
        switch self {
        case .oneWeek:
            return DateComponents(day: 7)
        case .tenDays:
            return DateComponents(day: 10)
        case .oneMonth:
            return DateComponents(month: 1)
        case .twoMonths:
            return DateComponents(month: 2)
        case .sixMonths:
            return DateComponents(month: 6)
        }
    }
}
