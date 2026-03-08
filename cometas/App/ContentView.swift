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
            return "task1"
        case .task2:
            return "task2"
        case .history:
            return "history"
        case .settings:
            return "setting"
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
    private let minSwipeDistance: CGFloat = 60

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
            SingleItemView(task: .primary)
                .highPriorityGesture(swipeGesture())
        case .task2:
            SingleItemView(task: .secondary)
                .highPriorityGesture(swipeGesture())
        case .history:
            HistoryView()
                .simultaneousGesture(historyRightSwipeGesture())
        case .settings:
            SettingView()
        }
    }

    private func swipeGesture() -> some Gesture {
        DragGesture().onEnded { value in
            let horizontal = value.translation.width
            let vertical = value.translation.height

            guard abs(horizontal) > abs(vertical), abs(horizontal) > minSwipeDistance else {
                return
            }

            guard let currentIndex = AppTab.allCases.firstIndex(of: selection) else {
                return
            }

            if horizontal < 0, currentIndex + 1 < AppTab.allCases.count {
                selection = AppTab.allCases[currentIndex + 1]
            } else if horizontal > 0, currentIndex - 1 >= 0 {
                selection = AppTab.allCases[currentIndex - 1]
            }
        }
    }

    private func historyRightSwipeGesture() -> some Gesture {
        DragGesture().onEnded { value in
            let horizontal = value.translation.width
            let vertical = value.translation.height

            guard selection == .history else { return }
            guard abs(horizontal) > abs(vertical), horizontal > minSwipeDistance else {
                return
            }

            guard let currentIndex = AppTab.allCases.firstIndex(of: selection) else {
                return
            }

            if currentIndex - 1 >= 0 {
                selection = AppTab.allCases[currentIndex - 1]
            }
        }
    }
}

#Preview {
    ContentView()
}
