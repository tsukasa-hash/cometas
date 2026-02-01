//
//  ContentView.swift
//  cometas
//
//  Created by 西岡宰 on 2026/01/17.
//

import SwiftUI

struct bkContentView: View {
    @AppStorage("taskName") var taskName: String = ""
    @AppStorage("interval") var interval: String = ""
    @State private var date = Date()
    @AppStorage("planedDoDate") var planedDoDate: String = ""
    @State var count: Int = 0
    var body: some View {
        VStack(spacing: 20) {
            Text("項目名")
            TextField("項目名", text: $taskName)
            Text(taskName)
            Text("間隔")
            TextField("間隔", text: $interval)
            Text(interval)
            DatePicker(
                "前回行った日",
                selection: $date,
                displayedComponents: [.date]
            )
            Text("次回予定日")
            
            HStack {
                Button(
                    action: {}, label: {Text("やった")}
                ).buttonStyle(.bordered)
                    .shadow(radius: 10)
                Button(
                    action: {}, label: {Text("今回はやらない")}
                ).buttonStyle(.bordered)
                    .shadow(radius: 10)
            }
        }
        VStack(spacing: 20) {
            Text("こんにちは！")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("私は山田太郎です")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("🎵 趣味：音楽を聴くこと 🎵")
                .font(.title2)
                .padding(16)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
            Text("SwiftUIを使って、いろんなアプリを作ってみたいです！")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(16)
                .foregroundColor(.white)
        }.padding(24)
            .background(Color.red)
            .cornerRadius(20)
            .padding(16)
            .shadow(radius: 10)
        Text("筋トレ回数：\(count)回")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(16)
            .background(Color.gray)
            .cornerRadius(10)
        HStack {
            Button(
                action: { count = max(0, count - 1) },
                label: {
                    Image(systemName: "minus")
                        .bold()
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 2)}
            )
            Button(
                action: { count += 1 },
                label: {
                    Image(systemName: "plus")
                        .bold()
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 2)}
            )
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    ContentView()
}
