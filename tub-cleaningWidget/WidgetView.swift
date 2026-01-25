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
    @Environment(\.widgetFamily) var family

    let entry: SimpleEntry

    var body: some View {
        
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
//            mediumView
            smallView
        default:
            smallView
        }
    }
    var smallView: some View {
        
        let status = dueStatus(nextDueDate: entry.nextDueDate)
        
       return VStack(spacing: 6) {
            Text(entry.itemName)
                .font(.title2)
                .fontWeight(.bold)
           HStack {
               VStack {
                   // 残り日数
                   Text(status.label)
                       .font(.caption)
                       .foregroundStyle(.secondary)
                   
                   HStack {
                       Text("\(status.days)")
                       Text("日")
                           .font(.caption)
                           .foregroundStyle(.secondary)
                   }
               }
                 Button(intent: DoneIntent()) {
//                     Image(systemName: "checkmark.bubble.fill")
//                     Image(systemName: "checkmark.square.fill")
                     Image(systemName: "checkmark.rectangle.portrait.fill")
                         .font(.title2)
                 }
                 .buttonStyle(.plain)
                 .tint(status.accent)
           }
        }
        .padding()
        .containerBackground(status.background, for: .widget)
    }
//    var mediumView: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(entry.itemName)
//                    .font(.headline)
//
//                Button(intent: DoneIntent()) {
//                    Label("やった", systemImage: "checkmark.bubble.fill")
//                }
//            }
//            Spacer()
//        }
//        .containerBackground(.fill.tertiary, for: .widget)
//    }

}
