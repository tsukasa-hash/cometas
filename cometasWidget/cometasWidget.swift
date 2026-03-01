//
//  cometasWidget.swift
//  cometasWidget
//
//  Created by ChatGPT on 2026/01/24.
//

import WidgetKit
import SwiftUI

struct cometasWidget: Widget {

    let kind: String = "cometasWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            WidgetView(entry: entry)   // ← ここで表示
        }
        .configurationDisplayName("cometasウィジェット")
        .description("ホーム画面とロック画面で残り日数を表示します")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
