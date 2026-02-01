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
    @Query private var timelines: [Timeline]
    @Query private var babies: [Baby]  // 保留Baby以向后兼容
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
        } else if timelines.isEmpty {
            // 没有时间线，显示时间线列表（可以创建新时间线）
            TimelineListView()
        } else {
            // 已有时间线，显示时间线列表
            TimelineListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Timeline.self, Baby.self, TimelinePhoto.self], inMemory: true)
}
