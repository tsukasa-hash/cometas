//
//  AppSettings.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

enum AppSettings {
    private enum Keys {
        static let item = "item"
        static let intervalRawValue = "intervalRawValue"
        static let lastDoneTimestamp = "lastDoneTimestamp"
        static let nextDueTimestamp = "nextDueTimestamp"
    }

    static let defaultInterval: Interval = .twoMonths

    static func itemName(defaults: UserDefaults = SharedStore.defaults) -> String {
        defaults.string(forKey: Keys.item) ?? ""
    }

    static func setItemName(_ item: String, defaults: UserDefaults = SharedStore.defaults) {
        defaults.set(item, forKey: Keys.item)
    }

    static func interval(defaults: UserDefaults = SharedStore.defaults) -> Interval {
        let raw = defaults.string(forKey: Keys.intervalRawValue)
        return Interval(rawValue: raw ?? defaultInterval.rawValue) ?? defaultInterval
    }

    static func setInterval(_ interval: Interval, defaults: UserDefaults = SharedStore.defaults) {
        defaults.set(interval.rawValue, forKey: Keys.intervalRawValue)
    }

    static func lastDoneDate(defaults: UserDefaults = SharedStore.defaults) -> Date {
        let ts = defaults.double(forKey: Keys.lastDoneTimestamp)
        return ts == 0 ? Date() : Date(timeIntervalSince1970: ts)
    }

    static func setLastDoneDate(_ date: Date, defaults: UserDefaults = SharedStore.defaults) {
        defaults.set(date.timeIntervalSince1970, forKey: Keys.lastDoneTimestamp)
    }

    static func nextDueDate(defaults: UserDefaults = SharedStore.defaults) -> Date {
        let ts = defaults.double(forKey: Keys.nextDueTimestamp)
        return ts == 0 ? Date() : Date(timeIntervalSince1970: ts)
    }

    static func setNextDueDate(_ date: Date, defaults: UserDefaults = SharedStore.defaults) {
        defaults.set(date.timeIntervalSince1970, forKey: Keys.nextDueTimestamp)
    }
}
