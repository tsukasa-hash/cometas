//
//  ContentView.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/17.
//

import SwiftUI

fileprivate enum AppTab: String, CaseIterable, Identifiable {
    case task1
    case task2
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .task1:
            return "タスク1"
        case .task2:
            return "タスク2"
        case .history:
            return "履歴"
        case .settings:
            return "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .task1:
            return "list.bullet"
        case .task2:
            return "list.bullet"
        case .history:
            return "rectangle.and.pencil.and.ellipsis"
        case .settings:
            return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selection: AppTab = .task1
    @StateObject private var historyStore = HistoryStore()

    var body: some View {
        TabView(selection: $selection) {
            contentView(for: .task1)
                .tag(AppTab.task1)
                .tabItem {
                    Image(systemName: AppTab.task1.systemImage)
                    Text(AppTab.task1.title)
                }

            contentView(for: .task2)
                .tag(AppTab.task2)
                .tabItem {
                    Image(systemName: AppTab.task2.systemImage)
                    Text(AppTab.task2.title)
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
        case .task1:
            NavigationStack {
                SingleItemView(task: .primary)
                    .navigationTitle("タスク1")
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .task2:
            NavigationStack {
                SingleItemView(task: .secondary)
                    .navigationTitle("タスク2")
                    .navigationBarTitleDisplayMode(.inline)
            }
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
