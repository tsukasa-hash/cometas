//
//  WidgetViewHelper.swift
//  cometasWidgetExtension
//
//  Created by ChatGPT on 2026/01/25.
//

import SwiftUI

enum DueStatus {
    case overdue(days: Int)
    case today(days: Int)  // 0
    case soon(days: Int)   // 1...3
    case normal(days: Int) // 4...

    
    var days: Int {
        switch self {
        case .overdue(let d),
             .soon(let d),
             .normal(let d),
             .today(let d):
            return d
        }
    }
    
    var label: String {
        switch self {
        case .overdue:
            return "期限切れ"
        case .today:
            return "今日"
        case .soon,
             .normal:
            return "あと"
        }
    }

    var background: Color {
        switch self {
        case .overdue:
            return .red.opacity(0.25)
        case .today, .soon:
            return .orange.opacity(0.25)
        case .normal:
            return .gray.opacity(0.15)
        }
    }

    var accent: Color {
        switch self {
        case .overdue:
            return .red
        case .today, .soon:
            return .orange
        case .normal:
            return .secondary
        }
    }
}

func dueStatus(nextDueDate: Date, now: Date = Date()) -> DueStatus {
    let cal = Calendar.current
    let startNow = cal.startOfDay(for: now)
    let startDue = cal.startOfDay(for: nextDueDate)

    let daysLeft = cal.dateComponents([.day], from: startNow, to: startDue).day ?? 0

    if daysLeft < 0 {
        return .overdue(days: abs(daysLeft))
    } else if daysLeft == 0 {
        return .today(days: daysLeft)
    } else if daysLeft <= 3 {
        return .soon(days: daysLeft)
    } else {
        return .normal(days: daysLeft)
    }
}
