//
//  TimelineSectionView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI

struct TimelineSectionView: View {
    let section: TimelineSection
    let onPhotoTap: (TimelinePhoto) -> Void
    let onPhotoLongPress: (TimelinePhoto) -> Void
    var onPhotoTapWithIndex: ((TimelinePhoto, Int) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线节点图标
            timelineDot

            // 右侧内容
            contentArea
        }
        .padding(.leading, 17)
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
                .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)

            Image(systemName: section.ageInfo.isMilestone ? (section.ageInfo.milestone?.icon ?? "star.fill") : "camera.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 28)
    }

    // MARK: - 右侧内容区
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 年龄/里程碑标签
            HStack(spacing: 8) {
                Text(section.ageInfo.displayText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(section.ageInfo.isMilestone ? .pink : .primary)

                if section.ageInfo.isMilestone {
                    Text("里程碑")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.pink, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                }

                Spacer()

                // 日期
                Text(DateCalculator.formatShortDate(section.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 照片区域 - 使用九宫格布局
            photoArea
        }
    }

    // MARK: - 照片区域
    @ViewBuilder
    private var photoArea: some View {
        if section.photos.count == 1 {
            // 单张照片 - 使用原有的 TimelineCell
            TimelineCell(
                photo: section.photos[0],
                ageInfo: section.ageInfo,
                onTap: { onPhotoTap(section.photos[0]) },
                onLongPress: { onPhotoLongPress(section.photos[0]) }
            )
        } else {
            // 多张照片 - 使用九宫格布局
            PhotoGridView(
                photos: section.photos,
                ageInfo: section.ageInfo,
                onPhotoTap: { photo, index in
                    if let handler = onPhotoTapWithIndex {
                        handler(photo, index)
                    } else {
                        onPhotoTap(photo)
                    }
                },
                onPhotoLongPress: { photo in
                    onPhotoLongPress(photo)
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TimelineSectionView(
            section: TimelineSection(
                date: Date(),
                ageInfo: AgeInfo(days: 30, months: 1, isMilestone: true, milestone: Milestone(days: 30, title: "满月", icon: "moon.fill")),
                photos: [
                    TimelinePhoto(localIdentifier: "1", exifDate: Date(), assetDate: Date()),
                    TimelinePhoto(localIdentifier: "2", exifDate: Date(), assetDate: Date()),
                    TimelinePhoto(localIdentifier: "3", exifDate: Date(), assetDate: Date()),
                    TimelinePhoto(localIdentifier: "4", exifDate: Date(), assetDate: Date())
                ]
            ),
            onPhotoTap: { _ in },
            onPhotoLongPress: { _ in }
        )

        TimelineSectionView(
            section: TimelineSection(
                date: Date(),
                ageInfo: AgeInfo(days: 100, months: 3, isMilestone: false, milestone: nil),
                photos: [
                    TimelinePhoto(localIdentifier: "5", exifDate: Date(), assetDate: Date())
                ]
            ),
            onPhotoTap: { _ in },
            onPhotoLongPress: { _ in }
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
