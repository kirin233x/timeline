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

@MainActor
class PhotoService: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    private let imageManager = PHImageManager.default()
    private var imageCache: [String: UIImage] = [:]
    private let maxCacheSize = 30  // 减少缓存数量，降低内存占用

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

    /// 从路径/标识符获取图片（支持本地路径和 PHAsset）
    func fetchImage(for path: String, size: CGSize = CGSize(width: 400, height: 400)) async -> UIImage? {
        // 检查缓存
        if let cachedImage = imageCache[path] {
            return cachedImage
        }

        // 管理缓存大小 - 更激进的清理策略
        if imageCache.count >= maxCacheSize {
            // 清理70%的缓存
            let keysToRemove = Array(imageCache.keys.prefix(Int(Double(imageCache.count) * 0.7)))
            for key in keysToRemove {
                imageCache.removeValue(forKey: key)
            }
        }

        // 判断是否为本地文件路径
        let isLocalFile = path.contains("Documents/Photos/") || path.starts(with: "/Photos/")

        if isLocalFile {
            // 使用PhotoStorageService获取完整路径（动态拼接，适配app重装）
            let fullPath = PhotoStorageService.shared.getFullPath(for: path)
            print("📷 从本地文件加载")
            print("   相对路径: \(path)")
            print("   完整路径: \(fullPath)")

            if let image = UIImage(contentsOfFile: fullPath) {
                // 调整大小 - 降采样减少内存占用
                let sizedImage = resizeImage(image, targetSize: size)
                imageCache[path] = sizedImage
                return sizedImage
            } else {
                print("❌ 无法加载本地文件: \(fullPath)")
            }
            return nil
        }

        // 从 PHAsset 加载（向后兼容）
        print("📷 从PHAsset加载: \(path)")
        guard let asset = fetchAsset(for: path) else {
            print("❌ 无法找到PHAsset: \(path)")
            return nil
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic  // 使用最快的可用版本
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.resizeMode = .fast  // 使用快速缩放模式

        return await withCheckedContinuation { continuation in
            let targetSize = CGSize(width: size.width, height: size.height)

            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
                if let image = image {
                    self.imageCache[path] = image
                }
                continuation.resume(returning: image)
            }
        }
    }

    /// 调整图片大小
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }

    /// 获取 PHAsset
    func fetchAsset(for localIdentifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return fetchResult.firstObject
    }

    /// 批量获取图片
    func fetchImages(for identifiers: [String], size: CGSize = CGSize(width: 200, height: 200)) async -> [String: UIImage] {
        var result: [String: UIImage] = [:]

        await withTaskGroup(of: (String, UIImage?).self) { group in
            for identifier in identifiers {
                group.addTask {
                    if let image = await self.fetchImage(for: identifier, size: size) {
                        return (identifier, image)
                    }
                    return (identifier, nil)
                }
            }

            for await (identifier, image) in group {
                if let image = image {
                    result[identifier] = image
                }
            }
        }

        return result
    }

    /// 获取原始高清图片
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

            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
                continuation.resume(returning: image)
            }
        }
    }

    /// 清除缓存
    func clearCache() {
        imageCache.removeAll()
    }
}
