//
//  SharedStore.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

enum SharedStore {

    static let appGroupID = "group.com.tsukasa.nishioka.cometas"

    static let defaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            fatalError("AppGroup UserDefaults が取得できません")
        }
        return defaults
    }()

    // keys
    static let historyKey = "historyEntries"
}

