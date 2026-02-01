//
//  ContentView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var babies: [Baby]
    @State private var isInitialized = false

    var body: some View {
        if !isInitialized {
            // 显示加载界面，等待数据初始化
            ProgressView("加载中...")
                .onAppear {
                    // 延迟一点以确保数据已加载
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isInitialized = true
                    }
                }
        } else if babies.isEmpty {
            // 没有宝宝档案，显示欢迎页
            OnboardingView()
        } else {
            // 已有宝宝档案，显示时间线
            TimelineView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Baby.self, TimelinePhoto.self], inMemory: true)
}
