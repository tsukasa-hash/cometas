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
}
