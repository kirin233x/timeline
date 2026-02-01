//
//  PhotoStorageService.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import UIKit
import Photos
import ImageIO
import PhotosUI
import _PhotosUI_SwiftUI

struct SavedPhoto {
    let localPath: String
    let image: UIImage
    let exifData: EXIFData?
}

struct PhotoStorageService {
    static let shared = PhotoStorageService()

    private let documentsDirectory: URL
    private let photosDirectory: URL

    init() {
        let fileManager = FileManager.default
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsDirectory.appendingPathComponent("Photos")

        // 创建照片目录
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    /// 从 PhotosPickerItem 加载图片并异步保存到应用沙盒
    func savePhoto(from item: PhotosPickerItem, priority: TaskPriority = .userInitiated) async -> SavedPhoto? {
        // 在后台线程加载数据
        return await Task(priority: priority) {
            // 加载图片数据
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return nil
            }

            // 生成唯一文件名
            let filename = "\(UUID().uuidString).jpg"
            let fileURL = photosDirectory.appendingPathComponent(filename)

            // 同步写入文件（很快，不会卡顿）
            do {
                try data.write(to: fileURL)
            } catch {
                print("保存图片失败: \(error)")
                return nil
            }

            // 在后台解析 EXIF（避免卡顿）
            let exifData = EXIFService.extractEXIF(from: data)

            // 返回相对路径（从/Documents/Photos/开始），不包含UUID
            let relativePath = "/Photos/\(filename)"

            return SavedPhoto(
                localPath: relativePath,  // 存储相对路径
                image: image,
                exifData: exifData
            )
        }.value
    }

    /// 批量保存照片（并发处理，提高性能）
    func savePhotos(from items: [PhotosPickerItem]) async -> [SavedPhoto] {
        await withTaskGroup(of: SavedPhoto?.self) { group in
            for item in items {
                await group.addTask(priority: .userInitiated) {
                    await self.savePhoto(from: item, priority: .userInitiated)
                }
            }

            var photos: [SavedPhoto] = []
            for await photo in group {
                if let photo = photo {
                    photos.append(photo)
                }
            }
            return photos
        }
    }

    /// 从本地路径加载图片
    func loadImage(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }

    /// 删除图片（支持相对路径和完整路径）
    func deletePhoto(at path: String) {
        let fullPath = getFullPath(for: path)
        try? FileManager.default.removeItem(atPath: fullPath)
        print("🗑️ 删除照片: \(fullPath)")
    }

    /// 获取完整的文件路径（从相对路径转换为完整路径）
    func getFullPath(for relativePath: String) -> String {
        // 如果已经是完整路径（向后兼容旧数据）
        if relativePath.hasPrefix("/var/") || relativePath.hasPrefix("/") && !relativePath.starts(with: "/Photos/") {
            return relativePath
        }

        // 相对路径格式：/Photos/xxx.jpg
        // 拼接当前Documents目录
        return documentsDirectory.appendingPathComponent(relativePath).path
    }
}
