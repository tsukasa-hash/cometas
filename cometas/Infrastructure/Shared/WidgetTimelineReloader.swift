//
//  WidgetTimelineReloader.swift
//  cometas
//
//  Created by Codex on 2026/02/28.
//

import Foundation
import WidgetKit

protocol WidgetTimelineReloading {
    func reload()
}

struct WidgetCenterTimelineReloader: WidgetTimelineReloading {
    private let kind: String

    init(kind: String = "cometasWidget") {
        self.kind = kind
    }

    func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

struct NoopWidgetTimelineReloader: WidgetTimelineReloading {
    func reload() {}
}
