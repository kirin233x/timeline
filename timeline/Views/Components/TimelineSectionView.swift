//
//  TimelineSectionView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI

struct TimelineSectionView: View {
    let section: TimelineSection
    let isEditMode: Bool
    let onPhotoTap: (TimelinePhoto) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线节点图标（只显示圆点，不要线）
            timelineDot

            // 右侧内容
            contentArea
        }
        .padding(.leading, 17)  // 让圆点中心对齐垂直线（30+1=31，17+14=31）
    }

    // MARK: - 时间线节点图标
    private var timelineDot: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.pink, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 28, height: 28)

            Image(systemName: section.ageInfo.isMilestone ? (section.ageInfo.milestone?.icon ?? "star.fill") : "camera.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 28)
    }

    // MARK: - 右侧内容区
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 年龄标签
            Text(section.ageInfo.displayText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )

            // 照片区域
            if section.photos.count == 1 {
                // 单张照片
                photoCell(section.photos.first!)
            } else {
                // 多张照片 - 横向滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(section.photos) { photo in
                            photoCell(photo)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 照片单元格
    private func photoCell(_ photo: TimelinePhoto) -> some View {
        TimelineCell(
            photo: photo,
            ageInfo: section.ageInfo,
            onTap: { onPhotoTap(photo) },
            onLongPress: { onPhotoTap(photo) },
            isEditMode: isEditMode
        )
    }
}
