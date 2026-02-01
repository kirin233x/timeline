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
                // 照片缩略图
                ZStack(alignment: .topTrailing) {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

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

                // 拍摄时间 - 使用fixedSize确保完整显示
                Text(DateCalculator.formatShortDate(photo.captureDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: Constants.photoThumbnailSize)  // 确保VStack宽度固定
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            // 长按进入编辑模式
            onLongPress()
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        // 使用400x400尺寸，保证清晰度
        let targetSize = CGSize(width: 400, height: 400)

        print("🖼️ TimelineCell加载照片: \(photo.localIdentifier)")
        print("   是否本地存储: \(photo.isLocalStored)")

        image = await photoService.fetchImage(
            for: photo.localIdentifier,
            size: targetSize
        )

        if image != nil {
            print("   ✅ 加载成功")
        } else {
            print("   ❌ 加载失败")
        }
    }
}

#Preview {
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
    .padding()
}
