//
//  TimelineCell.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI

struct TimelineCell: View {
    let photo: TimelinePhoto
    let ageInfo: AgeInfo
    let onTap: () -> Void
    let onLongPress: () -> Void
    let isEditMode: Bool

    @StateObject private var photoService = PhotoService()
    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // 照片缩略图
                    Group {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Color.gray.opacity(0.2)
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }
                    .frame(width: Constants.photoThumbnailSize, height: Constants.photoThumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

                    // 编辑模式下显示删除按钮
                    if isEditMode {
                        Button(action: onLongPress) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                    }
                }

                // 拍摄时间
                Text(DateCalculator.formatShortDate(photo.captureDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: Constants.photoThumbnailSize)
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            onLongPress()
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        let targetSize = CGSize(width: 400, height: 400)
        image = await photoService.fetchImage(
            for: photo.localIdentifier,
            size: targetSize
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        TimelineCell(
            photo: TimelinePhoto(
                localIdentifier: "test",
                exifDate: Date(),
                assetDate: Date(),
                baby: Baby(name: "测试宝宝", birthDate: Date().addingTimeInterval(-30*24*3600))
            ),
            ageInfo: AgeInfo(days: 30, months: 1, isMilestone: true, milestone: Milestone(days: 30, title: "满月", icon: "moon.fill")),
            onTap: { print("Tapped") },
            onLongPress: { print("Long Pressed") },
            isEditMode: false
        )

        TimelineCell(
            photo: TimelinePhoto(
                localIdentifier: "test2",
                exifDate: Date(),
                assetDate: Date(),
                baby: Baby(name: "测试宝宝", birthDate: Date().addingTimeInterval(-30*24*3600))
            ),
            ageInfo: AgeInfo(days: 60, months: 2, isMilestone: false, milestone: nil),
            onTap: { print("Tapped") },
            onLongPress: { print("Long Pressed") },
            isEditMode: false
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
