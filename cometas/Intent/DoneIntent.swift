//
//  DoneIntent.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//
import AppIntents
import Foundation

struct DoneIntent: AppIntent {

    static var title: LocalizedStringResource = "やった"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WidgetDoneActionAdapter.run()
        }

        return .result()
    }
}
