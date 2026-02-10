//
//  PhotoGridView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI

/// WeChat Moments style photo grid layout
struct PhotoGridView: View {
    let photos: [TimelinePhoto]
    let ageInfo: AgeInfo
    let onPhotoTap: (TimelinePhoto, Int) -> Void
    let onPhotoLongPress: (TimelinePhoto) -> Void

    private let spacing: CGFloat = 3
    private let maxVisiblePhotos = 9
    private let itemSize: CGFloat = 80

    var body: some View {
        let photoCount = photos.count
        let visiblePhotos = Array(photos.prefix(maxVisiblePhotos))
        let hasMore = photoCount > maxVisiblePhotos
        let moreCount = photoCount - maxVisiblePhotos

        VStack(alignment: .leading, spacing: spacing) {
            switch min(photoCount, maxVisiblePhotos) {
            case 1:
                singlePhotoLayout(visiblePhotos[0])

            case 2:
                twoPhotosLayout(visiblePhotos)

            case 3:
                threePhotosLayout(visiblePhotos)

            case 4:
                fourPhotosLayout(visiblePhotos)

            case 5, 6:
                fiveOrSixPhotosLayout(visiblePhotos)

            default:
                nineGridLayout(visiblePhotos, hasMore: hasMore, moreCount: moreCount)
            }
        }
    }

    // MARK: - Single Photo

    private func singlePhotoLayout(_ photo: TimelinePhoto) -> some View {
        PhotoGridItem(
            photo: photo,
            index: 0,
            size: CGSize(width: itemSize * 2, height: itemSize * 2),
            showOverlay: false,
            moreCount: 0,
            onTap: { onPhotoTap(photo, 0) },
            onLongPress: { onPhotoLongPress(photo) }
        )
    }

    // MARK: - Two Photos

    private func twoPhotosLayout(_ photos: [TimelinePhoto]) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                PhotoGridItem(
                    photo: photo,
                    index: index,
                    size: CGSize(width: itemSize, height: itemSize),
                    showOverlay: false,
                    moreCount: 0,
                    onTap: { onPhotoTap(photo, index) },
                    onLongPress: { onPhotoLongPress(photo) }
                )
            }
        }
    }

    // MARK: - Three Photos

    private func threePhotosLayout(_ photos: [TimelinePhoto]) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                PhotoGridItem(
                    photo: photo,
                    index: index,
                    size: CGSize(width: itemSize, height: itemSize),
                    showOverlay: false,
                    moreCount: 0,
                    onTap: { onPhotoTap(photo, index) },
                    onLongPress: { onPhotoLongPress(photo) }
                )
            }
        }
    }

    // MARK: - Four Photos

    private func fourPhotosLayout(_ photos: [TimelinePhoto]) -> some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(0..<2, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: itemSize, height: itemSize),
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
                        size: CGSize(width: itemSize, height: itemSize),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }
        }
    }

    // MARK: - Five or Six Photos

    private func fiveOrSixPhotosLayout(_ photos: [TimelinePhoto]) -> some View {
        let count = photos.count

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: itemSize, height: itemSize),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }

            HStack(spacing: spacing) {
                ForEach(3..<count, id: \.self) { index in
                    PhotoGridItem(
                        photo: photos[index],
                        index: index,
                        size: CGSize(width: itemSize, height: itemSize),
                        showOverlay: false,
                        moreCount: 0,
                        onTap: { onPhotoTap(photos[index], index) },
                        onLongPress: { onPhotoLongPress(photos[index]) }
                    )
                }
            }
        }
    }

    // MARK: - Nine Grid Layout

    private func nineGridLayout(_ photos: [TimelinePhoto], hasMore: Bool, moreCount: Int) -> some View {
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
                                size: CGSize(width: itemSize, height: itemSize),
                                showOverlay: isLastVisible,
                                moreCount: moreCount,
                                onTap: { onPhotoTap(photos[index], index) },
                                onLongPress: { onPhotoLongPress(photos[index]) }
                            )
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
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: size.width, height: size.height)
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
            }

            // "More" overlay
            if showOverlay && moreCount > 0 {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: size.width, height: size.height)

                Text("+\(moreCount)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
        let targetSize = CGSize(
            width: size.width * 2,
            height: size.height * 2
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

        Text("4 Photos")
        PhotoGridView(
            photos: (0..<4).map { TimelinePhoto(localIdentifier: "\($0)", exifDate: Date(), assetDate: Date()) },
            ageInfo: AgeInfo(days: 30, months: 1, isMilestone: false, milestone: nil),
            onPhotoTap: { _, _ in },
            onPhotoLongPress: { _ in }
        )
    }
    .padding()
}
