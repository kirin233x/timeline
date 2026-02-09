//
//  PhotoImportViewModel.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import Foundation
import SwiftUI
import PhotosUI
import SwiftData

/// 发现的里程碑信息
struct DiscoveredMilestone: Identifiable {
    let id = UUID()
    let photo: SavedPhoto
    let milestone: Milestone
    let date: Date
}

/// 导入进度状态
enum ImportPhase {
    case selecting
    case importing
    case processing
    case completed
    case cancelled
}

@MainActor
class PhotoImportViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var phase: ImportPhase = .selecting
    @Published var progress: Double = 0
    @Published var currentIndex: Int = 0
    @Published var totalCount: Int = 0
    @Published var savedPhotos: [SavedPhoto] = []
    @Published var discoveredMilestones: [DiscoveredMilestone] = []
    @Published var currentMilestoneAnimation: DiscoveredMilestone?
    @Published var errorMessage: String?
    @Published var isShowingMilestoneAnimation = false

    private var importTask: Task<Void, Never>?
    private var isCancelled = false

    var progressText: String {
        switch phase {
        case .selecting:
            return "选择照片"
        case .importing:
            return "正在导入 \(currentIndex)/\(totalCount)"
        case .processing:
            return "正在处理..."
        case .completed:
            return "导入完成"
        case .cancelled:
            return "已取消"
        }
    }

    var canCancel: Bool {
        phase == .importing || phase == .processing
    }

    /// 开始导入照片
    func startImport(to timeline: Timeline, context: ModelContext) {
        guard !selectedItems.isEmpty else { return }

        isCancelled = false
        phase = .importing
        totalCount = selectedItems.count
        currentIndex = 0
        progress = 0
        savedPhotos = []
        discoveredMilestones = []

        let items = selectedItems
        let milestones = timeline.getMilestones()

        importTask = Task {
            await performImport(
                items: items,
                timeline: timeline,
                milestones: milestones,
                context: context
            )
        }
    }

    /// 取消导入
    func cancelImport() {
        isCancelled = true
        importTask?.cancel()
        phase = .cancelled
    }

    /// 重置状态
    func reset() {
        selectedItems = []
        phase = .selecting
        progress = 0
        currentIndex = 0
        totalCount = 0
        savedPhotos = []
        discoveredMilestones = []
        currentMilestoneAnimation = nil
        errorMessage = nil
        isCancelled = false
    }

    // MARK: - Private

    private func performImport(
        items: [PhotosPickerItem],
        timeline: Timeline,
        milestones: [Milestone],
        context: ModelContext
    ) async {
        for (index, item) in items.enumerated() {
            // 检查取消
            guard !isCancelled && !Task.isCancelled else {
                phase = .cancelled
                return
            }

            currentIndex = index + 1
            progress = Double(index) / Double(totalCount)

            // 保存照片
            if let savedPhoto = await PhotoStorageService.shared.savePhoto(from: item) {
                savedPhotos.append(savedPhoto)

                // 检查是否匹配里程碑
                if let photoDate = savedPhoto.exifData?.dateTimeOriginal {
                    let daysSinceBase = Calendar.current.dateComponents(
                        [.day],
                        from: timeline.baseDate,
                        to: photoDate
                    ).day ?? 0

                    if let matchedMilestone = milestones.first(where: { $0.days == daysSinceBase }) {
                        let discovered = DiscoveredMilestone(
                            photo: savedPhoto,
                            milestone: matchedMilestone,
                            date: photoDate
                        )
                        discoveredMilestones.append(discovered)

                        // 显示里程碑动画
                        await showMilestoneAnimation(discovered)
                    }
                }

                // 创建 TimelinePhoto 记录
                let timelinePhoto = TimelinePhoto(
                    localIdentifier: savedPhoto.localPath,
                    exifDate: savedPhoto.exifData?.dateTimeOriginal,
                    assetDate: Date(),
                    timeline: timeline
                )

                if let location = savedPhoto.exifData?.location {
                    timelinePhoto.latitude = location.coordinate.latitude
                    timelinePhoto.longitude = location.coordinate.longitude
                }

                timelinePhoto.cameraModel = savedPhoto.exifData?.cameraModel
                timelinePhoto.lensModel = savedPhoto.exifData?.lensModel

                context.insert(timelinePhoto)
            }

            // 更新进度
            progress = Double(index + 1) / Double(totalCount)

            // 小延迟让 UI 更新
            try? await Task.sleep(for: .milliseconds(50))
        }

        // 保存到数据库
        phase = .processing
        do {
            try context.save()
            phase = .completed
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }

    private func showMilestoneAnimation(_ milestone: DiscoveredMilestone) async {
        currentMilestoneAnimation = milestone
        isShowingMilestoneAnimation = true

        // 显示动画 2 秒
        try? await Task.sleep(for: .seconds(2))

        withAnimation(.easeOut(duration: 0.3)) {
            isShowingMilestoneAnimation = false
        }

        try? await Task.sleep(for: .milliseconds(300))
        currentMilestoneAnimation = nil
    }
}
