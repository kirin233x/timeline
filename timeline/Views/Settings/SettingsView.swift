//
//  SettingsView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var timelines: [Timeline]
    @Query private var photos: [TimelinePhoto]

    @State private var storageInfo: StorageService.StorageInfo?
    @State private var isLoadingStorage = true
    @State private var showClearCacheAlert = false
    @State private var showClearAllDataAlert = false
    @State private var isClearingCache = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 存储空间
                Section {
                    if isLoadingStorage {
                        HStack {
                            Text("计算中...")
                                .foregroundStyle(.secondary)
                            Spacer()
                            ProgressView()
                        }
                    } else if let info = storageInfo {
                        StorageRowView(
                            icon: "photo.fill",
                            iconColor: .blue,
                            title: "照片存储",
                            detail: "\(info.photoCount) 张",
                            size: info.formattedPhotosSize
                        )

                        StorageRowView(
                            icon: "square.grid.2x2.fill",
                            iconColor: .orange,
                            title: "缩略图缓存",
                            detail: "\(info.thumbnailCount) 个",
                            size: info.formattedThumbnailCacheSize
                        )

                        StorageRowView(
                            icon: "person.circle.fill",
                            iconColor: .purple,
                            title: "图标缓存",
                            detail: nil,
                            size: info.formattedIconsCacheSize
                        )

                        HStack {
                            Label {
                                Text("总占用空间")
                                    .fontWeight(.semibold)
                            } icon: {
                                Image(systemName: "internaldrive.fill")
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            Text(info.formattedTotalSize)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("存储空间")
                } footer: {
                    Text("照片存储在本地设备上，不会上传到云端")
                }

                // MARK: - 数据管理
                Section("数据管理") {
                    Button {
                        showClearCacheAlert = true
                    } label: {
                        HStack {
                            Label("清除缩略图缓存", systemImage: "trash")
                                .foregroundStyle(.primary)
                            Spacer()
                            if isClearingCache {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isClearingCache)

                    Button(role: .destructive) {
                        showClearAllDataAlert = true
                    } label: {
                        Label("清除所有数据", systemImage: "trash.fill")
                    }
                }

                // MARK: - 统计信息
                Section("统计信息") {
                    HStack {
                        Label("时间线数量", systemImage: "timeline.selection")
                        Spacer()
                        Text("\(timelines.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("照片总数", systemImage: "photo.stack")
                        Spacer()
                        Text("\(photos.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - 关于
                Section("关于") {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("隐私政策", systemImage: "hand.raised.fill")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("关于时间线", systemImage: "info.circle.fill")
                    }

                    HStack {
                        Label("版本", systemImage: "number")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - 支持
                Section("支持与反馈") {
                    Link(destination: URL(string: "mailto:support@timeline-app.com")!) {
                        Label("联系我们", systemImage: "envelope.fill")
                    }

                    Link(destination: URL(string: "https://github.com/timeline-app/feedback")!) {
                        Label("提交反馈", systemImage: "bubble.left.and.exclamationmark.bubble.right.fill")
                    }

                    Button {
                        requestAppReview()
                    } label: {
                        Label("给个好评", systemImage: "star.fill")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadStorageInfo()
            }
            .refreshable {
                await loadStorageInfo()
            }
            .alert("清除缩略图缓存", isPresented: $showClearCacheAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    Task { await clearThumbnailCache() }
                }
            } message: {
                Text("缩略图会在下次查看照片时自动重新生成，不会影响原始照片")
            }
            .alert("清除所有数据", isPresented: $showClearAllDataAlert) {
                Button("取消", role: .cancel) {}
                Button("清除所有", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("这将删除所有时间线、照片和缓存数据，此操作不可撤销！")
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadStorageInfo() async {
        isLoadingStorage = true
        storageInfo = await StorageService.shared.calculateStorageUsage()
        isLoadingStorage = false
    }

    private func clearThumbnailCache() async {
        isClearingCache = true
        do {
            try await StorageService.shared.clearThumbnailCache()
            await PhotoService.shared.clearCache()
            await loadStorageInfo()
        } catch {
            print("清除缓存失败: \(error)")
        }
        isClearingCache = false
    }

    private func clearAllData() {
        // 删除所有时间线（会级联删除照片）
        for timeline in timelines {
            modelContext.delete(timeline)
        }

        // 清除文件系统
        Task {
            try? await StorageService.shared.clearThumbnailCache()
            try? await StorageService.shared.clearIconsCache()

            // 清除照片目录
            let fileManager = FileManager.default
            let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let photosDir = documentsDir.appendingPathComponent("Photos")
            try? fileManager.removeItem(at: photosDir)
            try? fileManager.createDirectory(at: photosDir, withIntermediateDirectories: true)

            await loadStorageInfo()
        }
    }

    private func requestAppReview() {
        // 实际应用中应使用 StoreKit 的 requestReview
        // 这里只是占位
    }
}

// MARK: - Storage Row View

struct StorageRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String?
    let size: String

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let detail = detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            Spacer()

            Text(size)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Timeline.self, TimelinePhoto.self], inMemory: true)
}
