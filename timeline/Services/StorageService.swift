//
//  StorageService.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import Foundation
import UIKit

/// 存储管理服务 - 计算和管理 app 存储空间
actor StorageService {
    static let shared = StorageService()

    private init() {}

    // MARK: - Storage Info

    struct StorageInfo {
        let photosSize: Int64           // 照片存储大小
        let thumbnailCacheSize: Int64   // 缩略图缓存大小
        let iconsCacheSize: Int64       // 图标缓存大小
        let totalSize: Int64            // 总占用
        let photoCount: Int             // 照片数量
        let thumbnailCount: Int         // 缩略图数量

        var formattedPhotosSize: String { ByteCountFormatter.string(fromByteCount: photosSize, countStyle: .file) }
        var formattedThumbnailCacheSize: String { ByteCountFormatter.string(fromByteCount: thumbnailCacheSize, countStyle: .file) }
        var formattedIconsCacheSize: String { ByteCountFormatter.string(fromByteCount: iconsCacheSize, countStyle: .file) }
        var formattedTotalSize: String { ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file) }
    }

    /// 计算存储使用情况
    func calculateStorageUsage() async -> StorageInfo {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        // 照片目录
        let photosDir = documentsDir.appendingPathComponent("Photos")
        let (photosSize, photoCount) = calculateDirectorySize(at: photosDir)

        // 图标目录
        let iconsDir = documentsDir.appendingPathComponent("TimelineIcons")
        let (iconsSize, _) = calculateDirectorySize(at: iconsDir)

        // 缩略图缓存目录
        let thumbnailDir = cachesDir.appendingPathComponent("Thumbnails")
        let (thumbnailSize, thumbnailCount) = calculateDirectorySize(at: thumbnailDir)

        let totalSize = photosSize + iconsSize + thumbnailSize

        return StorageInfo(
            photosSize: photosSize,
            thumbnailCacheSize: thumbnailSize,
            iconsCacheSize: iconsSize,
            totalSize: totalSize,
            photoCount: photoCount,
            thumbnailCount: thumbnailCount
        )
    }

    /// 清除缩略图缓存
    func clearThumbnailCache() async throws {
        let fileManager = FileManager.default
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let thumbnailDir = cachesDir.appendingPathComponent("Thumbnails")

        if fileManager.fileExists(atPath: thumbnailDir.path) {
            try fileManager.removeItem(at: thumbnailDir)
            try fileManager.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)
        }
    }

    /// 清除图标缓存
    func clearIconsCache() async throws {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconsDir = documentsDir.appendingPathComponent("TimelineIcons")

        if fileManager.fileExists(atPath: iconsDir.path) {
            try fileManager.removeItem(at: iconsDir)
            try fileManager.createDirectory(at: iconsDir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Private Helpers

    private func calculateDirectorySize(at url: URL) -> (Int64, Int) {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        var fileCount = 0

        guard fileManager.fileExists(atPath: url.path) else {
            return (0, 0)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if resourceValues.isRegularFile == true {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                    fileCount += 1
                }
            } catch {
                continue
            }
        }

        return (totalSize, fileCount)
    }
}
