//
//  PhotoDetailViewModel.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
class PhotoDetailViewModel: ObservableObject {
    @Published var photo: TimelinePhoto
    @Published var baby: Baby?
    @Published var fullImage: UIImage?
    @Published var exifData: EXIFData?
    @Published var locationName: String?
    @Published var isLoading = false

    private let photoService = PhotoService()
    private let locationService = LocationService()

    init(photo: TimelinePhoto, baby: Baby?) {
        self.photo = photo
        self.baby = baby
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // 检查是否为本地存储的照片
        if photo.isLocalStored {
            // 使用PhotoStorageService获取完整路径（支持相对路径）
            let fullPath = PhotoStorageService.shared.getFullPath(for: photo.localPath)
            print("📄 从本地加载照片")
            print("   相对路径: \(photo.localPath)")
            print("   完整路径: \(fullPath)")
            fullImage = UIImage(contentsOfFile: fullPath)
        } else {
            // 从 PHAsset 加载（向后兼容）
            fullImage = await photoService.fetchOriginalImage(for: photo.localIdentifier)
        }

        // 如果照片有 EXIF 数据（已保存），直接使用
        if photo.cameraModel != nil || photo.latitude != nil {
            // 重建 EXIFData
            exifData = EXIFData(
                dateTimeOriginal: photo.exifDate,
                cameraModel: photo.cameraModel,
                lensModel: photo.lensModel,
                iso: nil,
                aperture: nil,
                shutterSpeed: nil,
                focalLength: nil,
                location: photo.location
            )
        } else if !photo.isLocalStored {
            // 对于非本地照片，尝试从 PHAsset 提取
            if let asset = photoService.fetchAsset(for: photo.localIdentifier) {
                exifData = EXIFService.extractAllEXIF(from: asset)
            }
        }

        // 反向地理编码
        if let location = photo.location {
            locationName = await locationService.reverseGeocode(location: location)
        }
    }

    var captureDate: Date {
        photo.captureDate
    }

    var ageInfo: AgeInfo? {
        guard let baby = baby else {
            return nil
        }
        return photo.babyAge(birthDate: baby.birthDate)
    }

    var formattedDate: String {
        DateCalculator.formatDate(captureDate)
    }

    var hasLocation: Bool {
        photo.location != nil
    }
}
