//
//  ContentView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/17.
//

import SwiftUI

fileprivate enum AppTab: String, CaseIterable, Identifiable {
    case tasks
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks:
            return "タスク"
        case .history:
            return "履歴"
        case .settings:
            return "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .tasks:
            return "list.bullet"
        case .history:
            return "rectangle.and.pencil.and.ellipsis"
        case .settings:
            return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selection: AppTab = .tasks
    @StateObject private var historyStore = HistoryStore()

    var body: some View {
        TabView(selection: $selection) {
            contentView(for: .tasks)
                .tag(AppTab.tasks)
                .tabItem {
                    Image(systemName: AppTab.tasks.systemImage)
                    Text(AppTab.tasks.title)
                }

            contentView(for: .history)
                .tag(AppTab.history)
                .tabItem {
                    Image(systemName: AppTab.history.systemImage)
                    Text(AppTab.history.title)
                }

            contentView(for: .settings)
                .tag(AppTab.settings)
                .tabItem {
                    Image(systemName: AppTab.settings.systemImage)
                    Text(AppTab.settings.title)
                }
        }
        .environmentObject(historyStore)
    }

    @ViewBuilder
    private func contentView(for tab: AppTab) -> some View {
        switch tab {
        case .tasks:
            TaskListView()
        case .history:
            HistoryView()
        case .settings:
            SettingView()
        }
    }
}

#Preview {
    ContentView()
}
