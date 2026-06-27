//
//  DatePresentation.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

enum DatePresentation {
    static let locale = Locale(identifier: "ja_JP")

    static let ymdFormat = Date.FormatStyle.dateTime
        .locale(locale)
        .year()
        .month(.twoDigits)
        .day(.twoDigits)

    static func remainingDaysText(
        until dueDate: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let today = calendar.startOfDay(for: now)
        let dueDay = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0

        switch days {
        case 0:
            return "今日"
        case 1...:
            return "\(days)日"
        default:
            return "\(days)日"
        }
    }
}
