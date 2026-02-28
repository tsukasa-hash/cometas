//
//  NextDueDateCalculator.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation

enum NextDueDateCalculator {
    static func calculate(from baseDate: Date, interval: Interval, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: interval.dateComponent, to: baseDate) ?? baseDate
    }
}
