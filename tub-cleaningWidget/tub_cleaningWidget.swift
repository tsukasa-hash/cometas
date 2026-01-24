//
//  tub_cleaningWidget.swift
//  tub-cleaningWidget
//
//  Created by ChatGPT on 2026/01/24.
//

import WidgetKit
import SwiftUI

struct tub_cleaningWidget: Widget {

    let kind: String = "tub_cleaningWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            WidgetView(entry: entry)   // ← ここで表示
        }
        .configurationDisplayName("洗濯槽管理")
        .description("洗濯槽を洗ったかを記録します")
        .supportedFamilies([.systemSmall,.systemMedium])
    }
}

