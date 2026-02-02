//
//  PhotoService.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import UIKit
import Photos
import SwiftUI
import Combine
import ImageIO

// MARK: - Image Processing Utilities (no actor isolation, runs on any thread)

/// Efficiently downsample an image using ImageIO.
/// Unlike UIImage(contentsOfFile:) + resize, this only decodes the pixels
/// needed for the target size, using significantly less memory and CPU.
private func downsampleImage(at url: URL, maxPixelSize: CGFloat) -> UIImage? {
    let sourceOptions: [CFString: Any] = [
        kCGImageSourceShouldCache: false // Don't cache the full-size decoded image
    ]
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
        return nil
    }

    let downsampleOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true, // Respect EXIF orientation
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
    ]

    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}

/// Load full image from disk using ImageIO (more memory-efficient than UIImage(contentsOfFile:))
private func loadFullImage(at url: URL) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceShouldCacheImmediately: true
    ]
    guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    return UIImage(cgImage: cgImage)
}

/// Load a cached thumbnail from disk
private func loadCachedThumbnail(at url: URL) -> UIImage? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let options: [CFString: Any] = [
        kCGImageSourceShouldCacheImmediately: true
    ]
    guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    return UIImage(cgImage: cgImage)
}

/// Save a thumbnail image to disk cache
private func saveThumbnailToDisk(_ image: UIImage, at url: URL) {
    guard let data = image.jpegData(compressionQuality: 0.85) else { return }
    try? data.write(to: url, options: .atomic)
}

// MARK: - PhotoService

@MainActor
class PhotoService: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    static let shared = PhotoService()

    private let imageManager = PHImageManager.default()

    // MARK: - Memory Cache (NSCache: auto-evicts under memory pressure, no manual size management needed)
    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 80 * 1024 * 1024 // 80MB limit
        return cache
    }()

    // MARK: - Disk Thumbnail Cache (stored in Caches dir, system can reclaim if needed)
    private let thumbnailDir: URL

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        thumbnailDir = cacheDir.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)
    }

    // MARK: - Authorization

    /// 请求相册权限
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        }
    }

    /// 检查权限状态
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Thumbnail Loading (Three-level cache: Memory -> Disk -> Generate)

    /// 从路径/标识符获取缩略图（支持本地路径和 PHAsset）
    /// 三级缓存：内存缓存 -> 磁盘缩略图缓存 -> ImageIO 降采样生成
    func fetchImage(for path: String, size: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        let cacheKey = makeCacheKey(path: path, size: size)
        let nsKey = cacheKey as NSString

        // Level 1: Memory cache (instant, ~0ms)
        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }

        let isLocalFile = path.contains("Documents/Photos/") || path.starts(with: "/Photos/")

        if isLocalFile {
            return await fetchLocalThumbnail(path: path, size: size, cacheKey: cacheKey)
        }

        // PHAsset fallback (backward compatibility)
        return await fetchPHAssetThumbnail(identifier: path, size: size, cacheKey: cacheKey)
    }

    // MARK: - Full Image Loading (for detail view)

    /// 获取完整分辨率图片（用于详情页），在后台线程加载
    func fetchFullImage(for path: String) async -> UIImage? {
        let isLocalFile = path.contains("Documents/Photos/") || path.starts(with: "/Photos/")

        if isLocalFile {
            let fullPath = PhotoStorageService.shared.getFullPath(for: path)
            let fileURL = URL(fileURLWithPath: fullPath)

            return await Task.detached(priority: .userInitiated) {
                return loadFullImage(at: fileURL)
            }.value
        }

        // PHAsset fallback
        return await fetchOriginalImage(for: path)
    }

    // MARK: - Batch Loading

    /// 批量获取图片
    func fetchImages(for identifiers: [String], size: CGSize = CGSize(width: 200, height: 200)) async -> [String: UIImage] {
        var result: [String: UIImage] = [:]

        await withTaskGroup(of: (String, UIImage?).self) { group in
            for identifier in identifiers {
                group.addTask {
                    let image = await self.fetchImage(for: identifier, size: size)
                    return (identifier, image)
                }
            }

            for await (identifier, image) in group {
                if let image {
                    result[identifier] = image
                }
            }
        }

        return result
    }

    // MARK: - PHAsset Support

    /// 获取 PHAsset
    func fetchAsset(for localIdentifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return fetchResult.firstObject
    }

    /// 获取原始高清图片（PHAsset）
    func fetchOriginalImage(for localIdentifier: String) async -> UIImage? {
        guard let asset = fetchAsset(for: localIdentifier) else {
            return nil
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Cache Management

    /// 清除内存缓存
    func clearCache() {
        memoryCache.removeAllObjects()
    }

    /// 清除磁盘缩略图缓存
    func clearDiskCache() {
        try? FileManager.default.removeItem(at: thumbnailDir)
        try? FileManager.default.createDirectory(at: thumbnailDir, withIntermediateDirectories: true)
    }

    // MARK: - Private: Local File Thumbnail

    private func fetchLocalThumbnail(path: String, size: CGSize, cacheKey: String) async -> UIImage? {
        let fullPath = PhotoStorageService.shared.getFullPath(for: path)
        let thumbURL = thumbnailURL(for: cacheKey)
        let scale = UIScreen.main.scale
        let maxPixelSize = max(size.width, size.height) * scale
        let fileURL = URL(fileURLWithPath: fullPath)

        // Heavy work on background thread via Task.detached
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            // Check cancellation before starting
            guard !Task.isCancelled else { return nil }

            // Level 2: Disk thumbnail cache (~1-3ms, much faster than generating)
            if let cached = loadCachedThumbnail(at: thumbURL) {
                return cached
            }

            guard !Task.isCancelled else { return nil }

            // Level 3: Generate thumbnail via ImageIO downsampling
            // This only decodes the pixels needed for the target size,
            // using ~90% less memory than UIImage(contentsOfFile:) + resize
            guard let thumbnail = downsampleImage(at: fileURL, maxPixelSize: maxPixelSize) else {
                return nil
            }

            // Save to disk cache for next app launch
            saveThumbnailToDisk(thumbnail, at: thumbURL)

            return thumbnail
        }.value

        // Store in memory cache (back on main actor)
        if let image {
            memoryCache.setObject(image, forKey: cacheKey as NSString, cost: imageCost(image))
        }

        return image
    }

    // MARK: - Private: PHAsset Thumbnail

    private func fetchPHAssetThumbnail(identifier: String, size: CGSize, cacheKey: String) async -> UIImage? {
        guard let asset = fetchAsset(for: identifier) else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat // Use single-callback mode to avoid continuation crash
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.resizeMode = .fast

        let image = await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }

        if let image {
            memoryCache.setObject(image, forKey: cacheKey as NSString, cost: imageCost(image))
        }

        return image
    }

    // MARK: - Utilities

    /// Generate a cache key from path and size
    private func makeCacheKey(path: String, size: CGSize) -> String {
        // Use last path component (already a UUID) + dimensions for uniqueness
        let name = (path as NSString).lastPathComponent
            .replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".jpeg", with: "")
            .replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: ".heic", with: "")
        return "\(name)_\(Int(size.width))x\(Int(size.height))"
    }

    /// Get disk cache URL for a cache key
    private func thumbnailURL(for cacheKey: String) -> URL {
        thumbnailDir.appendingPathComponent(cacheKey + ".jpg")
    }

    /// Estimate memory cost of an image (for NSCache cost tracking)
    private func imageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
