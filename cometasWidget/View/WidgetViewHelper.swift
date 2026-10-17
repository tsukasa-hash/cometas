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

    var isOverdue: Bool {
        if case .overdue = self { return true }
        return false
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

    var accessoryDaysDisplayText: String {
        switch self {
        case .overdue(let d):
            return "-\(d)"
        case .today(let d), .soon(let d), .normal(let d):
            return "\(d)"
        }
    }

    var lockScreenCaption: String {
        switch self {
        case .overdue:
            return "期限切れ"
        case .today:
            return "今日が期限"
        case .soon, .normal:
            return "残り日数"
        }
    }

    var background: Color {
        switch self {
        case .overdue:
            return Color(red: 102 / 255, green: 125 / 255, blue: 107 / 255)
        case .today, .soon:
            return Color(red: 223 / 255, green: 229 / 255, blue: 220 / 255)
        case .normal:
            return Color(red: 251 / 255, green: 250 / 255, blue: 246 / 255)
        }
    }

    var foreground: Color {
        switch self {
        case .overdue:
            return .white
        case .today, .soon:
            return Color(red: 104 / 255, green: 123 / 255, blue: 107 / 255)
        case .normal:
            return Color(red: 134 / 255, green: 137 / 255, blue: 130 / 255)
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
