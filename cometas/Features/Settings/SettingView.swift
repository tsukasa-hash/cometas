//
//  SettingView.swift
//  cometas
//
//  Created by 西岡宰 on 2026/01/24.
//

import SwiftUI

struct SettingView: View {
    @State private var widgetDisplayTaskOption: WidgetDisplayTaskOption = AppSettings.widgetDisplayTaskOption()
    private let widgetReloader: WidgetTimelineReloading = WidgetCenterTimelineReloader()

    private var availableOptions: [WidgetDisplayTaskOption] {
        let taskOptions = AppSettings.registeredTasks().map { WidgetDisplayTaskOption(task: $0) }
        return taskOptions + [.shortestDue]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("表示するタスク") {
                    Picker("", selection: $widgetDisplayTaskOption) {
                        ForEach(availableOptions) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.gray)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: widgetDisplayTaskOption) { _, newValue in
            AppSettings.setWidgetDisplayTaskOption(newValue)
            widgetReloader.reload()
        }
        .onAppear {
            guard !availableOptions.contains(widgetDisplayTaskOption) else { return }
            widgetDisplayTaskOption = .shortestDue
            AppSettings.setWidgetDisplayTaskOption(.shortestDue)
            widgetReloader.reload()
        }
    }
}
