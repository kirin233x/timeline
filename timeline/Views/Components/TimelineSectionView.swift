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
        VStack(alignment: .leading, spacing: 16) {
            // 日期和年龄标记
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DateCalculator.formatShortDate(section.date))
                        .font(.headline)
                    if !section.photos.isEmpty {
                        Text("\(section.photos.count) 张照片")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                AgeBadge(ageInfo: section.ageInfo)
            }
            .padding(.horizontal)

            // 照片网格
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(section.photos) { photo in
                        ZStack(alignment: .topTrailing) {
                            TimelineCell(
                                photo: photo,
                                ageInfo: section.ageInfo,
                                onTap: { onPhotoTap(photo) }
                            )

                            // 编辑模式下显示删除按钮（overlay在右上角）
                            if isEditMode {
                                Button(action: { onPhotoTap(photo) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2)
                                }
                                .padding(.top, 4)
                                .padding(.trailing, 4)
                            }
                        }
                        .frame(width: Constants.photoThumbnailSize)  // 只限制宽度，让高度自适应
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let baby = Baby(name: "测试宝宝", birthDate: Date().addingTimeInterval(-30*24*3600))
    let photos = [
        TimelinePhoto(localIdentifier: "1", exifDate: Date(), assetDate: Date(), baby: baby),
        TimelinePhoto(localIdentifier: "2", exifDate: Date(), assetDate: Date(), baby: baby)
    ]
    let section = TimelineSection(
        date: Date(),
        ageInfo: AgeInfo(days: 30, months: 1, isMilestone: true, milestone: .fullMoon),
        photos: photos
    )

    return TimelineSectionView(section: section, isEditMode: false) { photo in
        print("Tapped photo: \(photo.localIdentifier)")
    }
}
