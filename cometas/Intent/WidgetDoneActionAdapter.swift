//
//  WidgetDoneActionAdapter.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

enum WidgetDoneActionAdapter {
    static func run() {
        let task = AppSettings.widgetDisplayTask()
        _ = RecordDoneUseCase(settings: UserDefaultsAppSettingsStore(task: task)).execute()
    }
}
