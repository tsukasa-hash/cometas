//
//  SingleItemView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/18.
//

import Foundation

import SwiftUI
import UIKit

struct SingleItemView: View {
    @StateObject private var viewModel: SingleItemViewModel
    @EnvironmentObject var historyStore: HistoryStore

    init(task: ManagedTask = .primary) {
        _viewModel = StateObject(wrappedValue: SingleItemViewModel(task: task))
    }

    // MARK: - View

    var body: some View {
        Form {
            Section("項目") {
                TextField(
                    "項目名",
                    text: Binding(
                        get: { viewModel.item },
                        set: { viewModel.setItem($0) }
                    )
                )
            }
            Section("間隔") {
                Picker(
                    "",
                    selection: Binding(
                        get: { viewModel.interval },
                        set: { viewModel.setInterval($0) }
                    )
                ) {
                    ForEach(Interval.displayOrder) {
                        Text($0.label).tag($0)
                    }
                }
            }

            Section("日付") {
                DatePicker(
                    "前回",
                    selection: Binding(
                        get: { viewModel.lastDoneDate },
                        set: { viewModel.setLastDoneDate($0) }
                    ),
                    displayedComponents: .date
                )
                .environment(\.locale, DatePresentation.locale)
                DatePicker(
                    "次回",
                    selection: Binding(
                        get: { viewModel.nextDueDate },
                        set: { _ in }
                    ),
                    displayedComponents: .date
                )
                .environment(\.locale, DatePresentation.locale)
                    .disabled(true)
            }

            Section {
                Button("やった") {
                    viewModel.handleDone(historyStore: historyStore)
                }
                .listRowBackground(Color.clear)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.black)
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)


                Button("今回はやらない") {
                    viewModel.handleSkip(historyStore: historyStore)
                }
                .listRowBackground(Color.clear)
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(.white)
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.gray, lineWidth: 1)
                )
//                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

            }
            .listRowSeparator(.hidden)
            
        }

        .onAppear {
            viewModel.reloadFromSettings()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            viewModel.reloadFromSettings()
            historyStore.reload()
        }
    }
}
