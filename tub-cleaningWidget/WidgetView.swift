//
//  WidgetView.swift
//  tub-cleaningWidgetExtension
//
//  Created by ChatGPT on 2026/01/24.
//

import SwiftUI
import WidgetKit
import AppIntents

struct WidgetView: View {

    let entry: SimpleEntry

    var body: some View {
        VStack(spacing: 8) {
            Text(entry.itemName)
                .font(.headline)
                .lineLimit(1)

            Button(intent: DoneIntent()) {
                Text("やった")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
