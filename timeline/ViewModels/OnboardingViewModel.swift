//
//  OnboardingViewModel.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftData
import Photos
import UIKit
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var babyName: String = ""
    @Published var birthDate: Date = Date()
    @Published var selectedAvatarLocalIdentifier: String?
    @Published var selectedPhotos: [SavedPhoto] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showPhotoPicker = false

    var isValid: Bool {
        !babyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createBaby(context: ModelContext) -> Baby? {
        guard isValid else {
            errorMessage = "请输入宝宝昵称"
            return nil
        }

        isProcessing = true
        defer { isProcessing = false }

        print("正在创建宝宝档案...")
        print("宝宝昵称: \(babyName)")
        print("出生日期: \(birthDate)")
        print("选择的照片数量: \(selectedPhotos.count)")

        // 创建宝宝档案
        let baby = Baby(
            name: babyName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate,
            avatarLocalIdentifier: selectedAvatarLocalIdentifier
        )

        context.insert(baby)

        // 如果选择了照片，添加到时间线
        if !selectedPhotos.isEmpty {
            addPhotosToTimeline(photos: selectedPhotos, to: baby, context: context)
        }

        do {
            try context.save()
            print("✅ 宝宝档案创建成功！")
            return baby
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            print("❌ 保存失败: \(error)")
            return nil
        }
    }

    private func addPhotosToTimeline(photos: [SavedPhoto], to baby: Baby, context: ModelContext) {
        print("📝 开始处理 \(photos.count) 张照片...")

        var successCount = 0

        for (index, savedPhoto) in photos.enumerated() {
            print("📝 处理照片 \(index + 1)/\(photos.count): \(savedPhoto.localPath)")

            // 使用 SavedPhoto 中的 EXIF 数据
            let exifData = savedPhoto.exifData

            if let exifDate = exifData?.dateTimeOriginal {
                print("  ✓ EXIF 日期: \(exifDate)")
            } else {
                print("  ⚠️  无 EXIF 日期，使用当前时间")
            }

            // 创建时间线照片（使用本地路径）
            let timelinePhoto = TimelinePhoto(
                localIdentifier: savedPhoto.localPath,
                exifDate: exifData?.dateTimeOriginal,
                assetDate: Date(),
                baby: baby
            )

            // 添加位置信息
            if let location = exifData?.location {
                timelinePhoto.latitude = location.coordinate.latitude
                timelinePhoto.longitude = location.coordinate.longitude
                print("  ✓ 包含位置信息")
            }

            // 添加设备信息
            if let camera = exifData?.cameraModel {
                timelinePhoto.cameraModel = camera
                print("  ✓ 拍摄设备: \(camera)")
            }

            timelinePhoto.lensModel = exifData?.lensModel

            context.insert(timelinePhoto)
            successCount += 1
        }

        print("📝 照片处理完成: 成功 \(successCount) 张")
    }
}
