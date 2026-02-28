//
//  WidgetView.swift
//  cometasWidgetExtension
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
        
        return GeometryReader {
            geo in
        VStack {
            Text(entry.itemName)
                .font(.title2)
                .foregroundColor(.black)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: geo.size.height * 0.6,alignment: .topLeading)
           HStack {
               VStack {
                   // 残り日数
                   Text(status.label)
                       .font(.caption)
                       .foregroundColor(.gray)
                       .frame(maxWidth: .infinity, alignment: .leading)
                   HStack {
                       Text("\(status.days)")
                           .frame(alignment: .leading)
                           .foregroundColor(.black)
                       Text("日")
                           .font(.caption)
                           .foregroundColor(.gray)
                           .frame(maxWidth: .infinity, alignment: .leading)
                   }
               }
                 Button(intent: DoneIntent()) {
//                     Image(systemName: "checkmark.bubble.fill")
//                     Image(systemName: "checkmark.square.fill")
//                     Image(systemName: "checkmark.rectangle.portrait.fill")
                     Image(systemName: "checkmark")
                         .font(.title2)
                 }
                 .buttonStyle(.bordered)
//                 .tint(status.accent)
                 .tint(.black)
                 .foregroundColor(.white)
                 .background(.black)
                 .cornerRadius(10)
           }
           .frame(height: geo.size.height * 0.4)
        }
        .containerBackground(status.background, for: .widget)
    }
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
