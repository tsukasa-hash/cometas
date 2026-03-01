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
        case .accessoryCircular:
            circularLockScreenView
        case .accessoryRectangular:
            rectangularLockScreenView
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
                     Image(systemName: "checkmark")
                         .font(.title2)
                 }
                 .buttonStyle(.bordered)
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
    var circularLockScreenView: some View {
        let status = dueStatus(nextDueDate: entry.nextDueDate)
        let daysText = status.accessoryDaysDisplayText
        return ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(daysText)
                    .font(accessoryDaysFont(for: daysText, family: .accessoryCircular))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                Text("日")
                    .font(.caption2)
            }
        }
    }

    var rectangularLockScreenView: some View {
        let status = dueStatus(nextDueDate: entry.nextDueDate)
        let daysText = "\(abs(status.days))"
        return HStack {
            VStack(alignment: .leading) {
                Text(entry.itemName)
                    .font(.caption2)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            VStack {
                Text(status.lockScreenCaption)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(daysText)
                        .font(accessoryDaysFont(for: daysText, family: .accessoryRectangular))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                        .layoutPriority(1)
                    Text("日")
                        .font(.caption)
                        .fixedSize()
                }
                
            }
        }
    }

    func accessoryDaysFont(for daysText: String, family: WidgetFamily) -> Font {
        switch family {
        case .accessoryCircular:
            switch daysText.count {
            case 0...2:
                return .system(size: 18, weight: .bold, design: .rounded)
            case 3:
                return .system(size: 16, weight: .bold, design: .rounded)
            case 4:
                return .system(size: 14, weight: .bold, design: .rounded)
            default:
                return .system(size: 12, weight: .bold, design: .rounded)
            }
        case .accessoryRectangular:
            switch daysText.count {
            case 0...2:
                return .title2.bold()
            case 3:
                return .title3.bold()
            case 4:
                return .headline.bold()
            default:
                return .subheadline.bold()
            }
        default:
            return .body.bold()
        }
    }
}
