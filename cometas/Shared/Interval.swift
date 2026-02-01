//
//  Interval.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

enum Interval: String, CaseIterable, Identifiable, Codable {
    case tenDays
    case oneWeek
    case oneMonth
    case twoMonths
    case sixMonths

    static let displayOrder: [Interval] = [
        .oneWeek,
        .tenDays,
        .oneMonth,
        .twoMonths,
        .sixMonths
    ]
    
    var id: Self { self }

    var label: String {
        switch self {
        case .oneWeek: return "1週間"
        case .tenDays: return "10日"
        case .oneMonth: return "1ヶ月"
        case .twoMonths: return "2ヶ月"
        case .sixMonths: return "6ヶ月"
        }
    }

    var dateComponent: DateComponents {
        switch self {
        case .oneWeek: return DateComponents(day: 7)
        case .tenDays: return DateComponents(day: 10)
        case .oneMonth: return DateComponents(month: 1)
        case .twoMonths: return DateComponents(month: 2)
        case .sixMonths: return DateComponents(month: 6)
        }
    }
}
