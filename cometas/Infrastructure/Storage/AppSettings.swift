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
    case task3
    case task4
    case task5
    case shortestDue

    var id: String { rawValue }

    var label: String {
        switch self {
        case .task1:
            return "タスク1"
        case .task2:
            return "タスク2"
        case .task3:
            return "タスク3"
        case .task4:
            return "タスク4"
        case .task5:
            return "タスク5"
        case .shortestDue:
            return "期限が近いもの"
        }
    }

    var task: ManagedTask? {
        switch self {
        case .task1: return .primary
        case .task2: return .secondary
        case .task3: return .tertiary
        case .task4: return .quaternary
        case .task5: return .quinary
        case .shortestDue: return nil
        }
    }

    init(task: ManagedTask) {
        switch task {
        case .primary: self = .task1
        case .secondary: self = .task2
        case .tertiary: self = .task3
        case .quaternary: self = .task4
        case .quinary: self = .task5
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
    private static let registeredTaskIDsKey = "registeredTaskIDs"

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
        case .tertiary:
            return numberedKeys(3)
        case .quaternary:
            return numberedKeys(4)
        case .quinary:
            return numberedKeys(5)
        }
    }

    private static func numberedKeys(_ number: Int) -> Keys {
        Keys(
            item: "item\(number)",
            intervalRawValue: "intervalRawValue\(number)",
            lastDoneTimestamp: "lastDoneTimestamp\(number)",
            nextDueTimestamp: "nextDueTimestamp\(number)"
        )
    }

    static let defaultInterval: Interval = .twoMonths
    static let maximumTaskCount = ManagedTask.allCases.count

    static func registeredTasks(defaults: UserDefaults = SharedStore.defaults) -> [ManagedTask] {
        if let storedValues = defaults.array(forKey: registeredTaskIDsKey) {
            var seenTasks = Set<ManagedTask>()
            return storedValues.compactMap { value -> ManagedTask? in
                guard let rawValue = (value as? NSNumber)?.intValue else { return nil }
                return ManagedTask(rawValue: rawValue)
            }
            .filter { seenTasks.insert($0).inserted }
        }

        return ManagedTask.allCases.filter { task in
            defaults.object(forKey: keys(for: task).item) != nil
        }
    }

    static func setRegisteredTaskOrder(
        _ tasks: [ManagedTask],
        defaults: UserDefaults = SharedStore.defaults
    ) {
        let registered = registeredTasks(defaults: defaults)
        let registeredSet = Set(registered)
        var seenTasks = Set<ManagedTask>()
        let orderedTasks = tasks.filter {
            registeredSet.contains($0) && seenTasks.insert($0).inserted
        }
        let missingTasks = registered.filter { !seenTasks.contains($0) }

        defaults.set(
            (orderedTasks + missingTasks).map(\.rawValue),
            forKey: registeredTaskIDsKey
        )
    }

    @discardableResult
    static func registerNextTask(
        defaults: UserDefaults = SharedStore.defaults,
        now: Date = Date()
    ) -> ManagedTask? {
        let registered = registeredTasks(defaults: defaults)
        guard let task = ManagedTask.allCases.first(where: { !registered.contains($0) }) else {
            return nil
        }

        setItemName("新しいタスク", task: task, defaults: defaults)
        setInterval(defaultInterval, task: task, defaults: defaults)
        setLastDoneDate(now, task: task, defaults: defaults)
        setNextDueDate(
            NextDueDateCalculator.calculate(from: now, interval: defaultInterval),
            task: task,
            defaults: defaults
        )

        let updated = (registered + [task]).map(\.rawValue)
        defaults.set(updated, forKey: registeredTaskIDsKey)
        return task
    }

    static func deleteTask(
        _ task: ManagedTask,
        defaults: UserDefaults = SharedStore.defaults
    ) {
        let updated = registeredTasks(defaults: defaults)
            .filter { $0 != task }
            .map(\.rawValue)
        defaults.set(updated, forKey: registeredTaskIDsKey)

        let taskKeys = keys(for: task)
        defaults.removeObject(forKey: taskKeys.item)
        defaults.removeObject(forKey: taskKeys.intervalRawValue)
        defaults.removeObject(forKey: taskKeys.lastDoneTimestamp)
        defaults.removeObject(forKey: taskKeys.nextDueTimestamp)

        if widgetDisplayTaskOption(defaults: defaults).task == task {
            setWidgetDisplayTaskOption(.shortestDue, defaults: defaults)
        }
    }

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
        let registered = registeredTasks(defaults: defaults)
        let candidates: [ManagedTask] = registered.isEmpty ? [.primary, .secondary] : registered

        if let selectedTask = option.task, candidates.contains(selectedTask) {
            return selectedTask
        }

        return candidates.min {
            nextDueDate(task: $0, defaults: defaults) < nextDueDate(task: $1, defaults: defaults)
        } ?? .primary
    }
}

protocol TaskRegistrationStoring {
    var registeredTasks: [ManagedTask] { get }
    func registerNextTask() -> ManagedTask?
    func deleteTask(_ task: ManagedTask)
    func setTaskOrder(_ tasks: [ManagedTask])
}

struct UserDefaultsTaskRegistrationStore: TaskRegistrationStoring {
    var registeredTasks: [ManagedTask] {
        AppSettings.registeredTasks()
    }

    func registerNextTask() -> ManagedTask? {
        AppSettings.registerNextTask()
    }

    func deleteTask(_ task: ManagedTask) {
        AppSettings.deleteTask(task)
    }

    func setTaskOrder(_ tasks: [ManagedTask]) {
        AppSettings.setRegisteredTaskOrder(tasks)
    }
}
