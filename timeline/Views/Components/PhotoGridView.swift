//
//  PhotoGridView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI

/// 类似微信朋友圈的九宫格照片布局
/// - 1张：大图
/// - 2张：左右各一
/// - 3张：上1下2
/// - 4张：2x2
/// - 5-6张：上2下3 / 2x3
/// - 7-9张：3x3
/// - 9+张：3x3 + 显示更多
struct PhotoGridView: View {
    let photos: [TimelinePhoto]
    let ageInfo: AgeInfo
    let onPhotoTap: (TimelinePhoto, Int) -> Void  // 添加索引参数用于浏览
    let onPhotoLongPress: (TimelinePhoto) -> Void

    private let spacing: CGFloat = 4
    private let maxVisiblePhotos = 9

    var body: some View {
        let photoCount = photos.count
        let visiblePhotos = Array(photos.prefix(maxVisiblePhotos))
        let hasMore = photoCount > maxVisiblePhotos
        let moreCount = photoCount - maxVisiblePhotos

        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let gridSize = calculateGridSize(for: photoCount, availableWidth: availableWidth)

            Group {
                switch min(photoCount, maxVisiblePhotos) {
                case 1:
                    singlePhotoLayout(visiblePhotos[0], size: gridSize.single)

                case 2:
                    twoPhotosLayout(visiblePhotos, size: gridSize.small)

                case 3:
                    threePhotosLayout(visiblePhotos, size: gridSize.small)

                case 4:
                    fourPhotosLayout(visiblePhotos, size: gridSize.small)

                case 5, 6:
                    fiveOrSixPhotosLayout(visiblePhotos, size: gridSize.small)

                default:
                    nineGridLayout(visiblePhotos, size: gridSize.small, hasMore: hasMore, moreCount: moreCount)
                }
            }
        }
        .frame(height: calculateHeight(for: photos.count))
    }

    // MARK: - Layout Calculations

    private struct GridSize {
        let single: CGFloat
        let small: CGFloat
    }

    private func calculateGridSize(for count: Int, availableWidth: CGFloat) -> GridSize {
        let singleSize = min(availableWidth * 0.7, 250)
        let smallSize = (availableWidth - spacing * 2) / 3

        return GridSize(single: singleSize, small: smallSize)
    }

    private func calculateHeight(for count: Int) -> CGFloat {
        let baseSize: CGFloat = 90

        switch count {
        case 1: return min(250, baseSize * 2.5)
        case 2: return baseSize
        case 3: return baseSize * 2 + spacing
        case 4: return baseSize * 2 + spacing
        case 5, 6: return baseSize * 2 + spacing
        default: return baseSize * 3 + spacing * 2
        }
    }

    // MARK: - Layouts

    private func singlePhotoLayout(_ photo: TimelinePhoto, size: CGFloat) -> some View {
        PhotoGridItem(
            photo: photo,
            index: 0,
            size: CGSize(width: size, height: size),
            showOverlay: false,
            moreCount: 0,
            onTap: { onPhotoTap(photo, 0) },
            onLongPress: { onPhotoLongPress(photo) }
        )
    }

    private func twoPhotosLayout(_ photos: [TimelinePhoto], size: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                PhotoGridItem(
                    photo: photo,
                    index: index,
                    size: CGSize(width: size * 1.5, height: size),
                    showOverlay: false,
                    moreCount: 0,
                    onTap: { onPhotoTap(photo, index) },
                    onLongPress: { onPhotoLongPress(photo) }
                )
            }
        }
    }

    private func threePhotosLayout(_ photos: [TimelinePhoto], size: CGFloat) -> some View {
        VStack(spacing: spacing) {
            // 上面一张大图
            PhotoGridItem(
                photo: photos[0],
                index: 0,
                size: CGSize(width: size * 3 + spacing * 2, height: size),
                showOverlay: false,
                moreCount: 0,
                onTap: { onPhotoTap(photos[0], 0) },
                onLongPress: { onPhotoLongPress(photos[0]) }
            )

            // 下面两张小图
            HStack(spacing: spacing) {
                ForEach(1..<3, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: size * 1.5 + spacing / 2, height: size),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }
        }
    }

    private func fourPhotosLayout(_ photos: [TimelinePhoto], size: CGFloat) -> some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(0..<2, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: size * 1.5, height: size),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }

            HStack(spacing: spacing) {
                ForEach(2..<4, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: size * 1.5, height: size),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }
        }
    }

    private func fiveOrSixPhotosLayout(_ photos: [TimelinePhoto], size: CGFloat) -> some View {
        let count = photos.count

        return VStack(spacing: spacing) {
            // 第一行：2或3张
            HStack(spacing: spacing) {
                ForEach(0..<min(3, count), id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: size, height: size),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }

            // 第二行
            HStack(spacing: spacing) {
                ForEach(3..<count, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: size, height: size),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }

                // 填充空位
                if count == 5 {
                    Color.clear.frame(width: size, height: size)
                }
            }
        }
    }

    private func nineGridLayout(_ photos: [TimelinePhoto], size: CGFloat, hasMore: Bool, moreCount: Int) -> some View {
        let count = photos.count

        return VStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col

                        if index < count {
                            let isLastVisible = index == count - 1 && hasMore

                            PhotoGridItem(
                                photo: photos[index],
                                index: index,
                                size: CGSize(width: size, height: size),
                                showOverlay: isLastVisible,
                                moreCount: moreCount,
                                onTap: { onPhotoTap(photos[index], index) },
                                onLongPress: { onPhotoLongPress(photos[index]) }
                            )
                        } else {
                            Color.clear.frame(width: size, height: size)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let photo: TimelinePhoto
    let index: Int
    let size: CGSize
    let showOverlay: Bool
    let moreCount: Int
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
            }

            // "更多" 遮罩
            if showOverlay && moreCount > 0 {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size.width, height: size.height)

                Text("+\(moreCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onTap) {
                Label("查看", systemImage: "eye")
            }

            Button(role: .destructive, action: onLongPress) {
                Label("删除", systemImage: "trash")
            }
        }
        .task(id: photo.localIdentifier) {
            await loadImage()
        }
    }

    private func loadImage() async {
        // 根据尺寸选择合适的缩略图大小
        let targetSize = CGSize(
            width: max(size.width, size.height) * 2,
            height: max(size.width, size.height) * 2
        )

        let loadedImage = await PhotoService.shared.fetchImage(
            for: photo.localIdentifier,
            size: targetSize
        )

        guard !Task.isCancelled else { return }

        withAnimation(.easeIn(duration: 0.15)) {
            image = loadedImage
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("1 Photo")
        PhotoGridView(
            photos: [TimelinePhoto(localIdentifier: "1", exifDate: Date(), assetDate: Date())],
            ageInfo: AgeInfo(days: 30, months: 1, isMilestone: false, milestone: nil),
            onPhotoTap: { _, _ in },
            onPhotoLongPress: { _ in }
        )
        .frame(height: 200)

        Text("4 Photos")
        PhotoGridView(
            photos: (0..<4).map { TimelinePhoto(localIdentifier: "\($0)", exifDate: Date(), assetDate: Date()) },
            ageInfo: AgeInfo(days: 30, months: 1, isMilestone: false, milestone: nil),
            onPhotoTap: { _, _ in },
            onPhotoLongPress: { _ in }
        )
        .frame(height: 200)
    }
    .padding()
}
