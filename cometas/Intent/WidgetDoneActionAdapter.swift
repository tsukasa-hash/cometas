//
//  WidgetDoneActionAdapter.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

enum WidgetDoneActionAdapter {
    static func run() {
        _ = RecordDoneUseCase().execute()
    }
}
