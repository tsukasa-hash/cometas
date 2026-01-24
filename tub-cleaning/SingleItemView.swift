//
//  SingleItemView.swift
//  tub-cleaning
//
//  Created by ChatGPT on 2026/01/18.
//

import Foundation

import SwiftUI
import WidgetKit

struct SingleItemView: View {
    
    // MARK: - AppStorage（保存用）
    @AppStorage("item", store: SharedStore.defaults)
    private var item: String = ""

    @AppStorage("intervalRawValue", store: SharedStore.defaults)
    private var intervalRawValue: String = Interval.twoMonths.rawValue

    @AppStorage("lastDoneTimestamp", store: SharedStore.defaults)
    private var lastDoneTimestamp: Double = Date().timeIntervalSince1970

    @AppStorage("nextDueTimestamp", store: SharedStore.defaults)
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
        .onChange(of: item) {
            WidgetCenter.shared.reloadTimelines(
                ofKind: "tub_cleaningWidget"
            )
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            historyStore.reload()
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
