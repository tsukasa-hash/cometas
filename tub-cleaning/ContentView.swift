//
//  ContentView.swift
//  tub-cleaning
//
//  Created by 西岡宰 on 2026/01/17.
//

import SwiftUI

struct ContentView: View {
    @State var selection: Int = 1
    @StateObject private var historyStore = HistoryStore()
    var body: some View {
        TabView(selection: $selection) {
            
            SingleItemView()
                .tabItem {
                    Label("main", systemImage: "list.bullet")
                }
                .tag(1)
            HistoryView()
                .tabItem {
                    Label("history", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
                .tag(2)
            SettingView()
                .tabItem {
                    Label("setting", systemImage: "gearshape")
                }
                .tag(3)
        }
        .environmentObject(historyStore)
    }
}

#Preview {
    ContentView()
}
