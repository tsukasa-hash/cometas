//
//  SharedLogic.swift
//  cometas
//
//  Created by ChatGPT on 2026/01/24.
//

import Foundation

enum DoneAction {

    static func done() {
        WidgetDoneActionAdapter.run()
    }
}
