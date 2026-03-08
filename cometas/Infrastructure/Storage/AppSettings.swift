//
//  AppSettings.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

enum WidgetDisplayTaskOption: String, CaseIterable, Identifiable {
    case task1
    case task2
    case shortestDue

    var id: String { rawValue }

    var label: String {
        switch self {
        case .task1:
            return "タスク1"
        case .task2:
            return "タスク2"
        case .shortestDue:
            return "期限が近いもの"
        }
    }
}

enum AppSettings {
    private struct Keys {
        let item: String
        let intervalRawValue: String
        let lastDoneTimestamp: String
        let nextDueTimestamp: String
    }

    private static let widgetDisplayTaskOptionKey = "widgetDisplayTaskOption"

    private static func keys(for task: ManagedTask) -> Keys {
        switch task {
        case .primary:
            return Keys(
                item: "item",
                intervalRawValue: "intervalRawValue",
                lastDoneTimestamp: "lastDoneTimestamp",
                nextDueTimestamp: "nextDueTimestamp"
            )
        case .secondary:
            return Keys(
                item: "item2",
                intervalRawValue: "intervalRawValue2",
                lastDoneTimestamp: "lastDoneTimestamp2",
                nextDueTimestamp: "nextDueTimestamp2"
            )
        }
    }

    static let defaultInterval: Interval = .twoMonths

    static func itemName(task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) -> String {
        let keys = keys(for: task)
        return defaults.string(forKey: keys.item) ?? ""
    }

    static func setItemName(_ item: String, task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) {
        let keys = keys(for: task)
        defaults.set(item, forKey: keys.item)
    }

    static func interval(task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) -> Interval {
        let keys = keys(for: task)
        let raw = defaults.string(forKey: keys.intervalRawValue)
        return Interval(rawValue: raw ?? defaultInterval.rawValue) ?? defaultInterval
    }

    static func setInterval(_ interval: Interval, task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) {
        let keys = keys(for: task)
        defaults.set(interval.rawValue, forKey: keys.intervalRawValue)
    }

    static func lastDoneDate(task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) -> Date {
        let keys = keys(for: task)
        let ts = defaults.double(forKey: keys.lastDoneTimestamp)
        return ts == 0 ? Date() : Date(timeIntervalSince1970: ts)
    }

    static func setLastDoneDate(_ date: Date, task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) {
        let keys = keys(for: task)
        defaults.set(date.timeIntervalSince1970, forKey: keys.lastDoneTimestamp)
    }

    static func nextDueDate(task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) -> Date {
        let keys = keys(for: task)
        let ts = defaults.double(forKey: keys.nextDueTimestamp)
        return ts == 0 ? Date() : Date(timeIntervalSince1970: ts)
    }

    static func setNextDueDate(_ date: Date, task: ManagedTask = .primary, defaults: UserDefaults = SharedStore.defaults) {
        let keys = keys(for: task)
        defaults.set(date.timeIntervalSince1970, forKey: keys.nextDueTimestamp)
    }

    static func widgetDisplayTaskOption(defaults: UserDefaults = SharedStore.defaults) -> WidgetDisplayTaskOption {
        let raw = defaults.string(forKey: widgetDisplayTaskOptionKey)
        return WidgetDisplayTaskOption(rawValue: raw ?? WidgetDisplayTaskOption.task1.rawValue) ?? .task1
    }

    static func setWidgetDisplayTaskOption(
        _ option: WidgetDisplayTaskOption,
        defaults: UserDefaults = SharedStore.defaults
    ) {
        defaults.set(option.rawValue, forKey: widgetDisplayTaskOptionKey)
    }

    static func widgetDisplayTask(defaults: UserDefaults = SharedStore.defaults) -> ManagedTask {
        let option = widgetDisplayTaskOption(defaults: defaults)
        switch option {
        case .task1:
            return .primary
        case .task2:
            return .secondary
        case .shortestDue:
            let primaryNextDue = nextDueDate(task: .primary, defaults: defaults)
            let secondaryNextDue = nextDueDate(task: .secondary, defaults: defaults)
            return primaryNextDue <= secondaryNextDue ? .primary : .secondary
        }
    }
}
