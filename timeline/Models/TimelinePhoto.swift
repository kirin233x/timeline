//
//  TimelinePhoto.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class TimelinePhoto {
    var id: UUID
    var localIdentifier: String  // 保留用于向后兼容，现在存储本地路径
    var exifDate: Date?
    var assetDate: Date
    var manualDate: Date?  // 用户手动设置的日期
    var addedAt: Date
    var latitude: Double?
    var longitude: Double?
    var cameraModel: String?
    var lensModel: String?

    @Relationship var baby: Baby?
    @Relationship var timeline: Timeline?  // 新增：支持通用Timeline

    init(localIdentifier: String, exifDate: Date?, assetDate: Date, baby: Baby) {
        self.id = UUID()
        self.localIdentifier = localIdentifier  // 现在这个字段存储本地文件路径
        self.exifDate = exifDate
        self.assetDate = assetDate
        self.manualDate = nil
        self.addedAt = Date()
        self.baby = baby
        self.timeline = nil
    }

    // 新增：支持Timeline的初始化
    init(localIdentifier: String, exifDate: Date?, assetDate: Date, timeline: Timeline) {
        self.id = UUID()
        self.localIdentifier = localIdentifier
        self.exifDate = exifDate
        self.assetDate = assetDate
        self.manualDate = nil
        self.addedAt = Date()
        self.baby = nil
        self.timeline = timeline
    }

    /// 获取实际拍摄时间（优先使用手动设置的日期）
    var captureDate: Date {
        manualDate ?? exifDate ?? assetDate
    }

    /// 是否手动修改过日期
    var hasManualDate: Bool {
        manualDate != nil
    }

    /// 获取本地文件路径
    var localPath: String {
        return localIdentifier
    }

    /// 是否为本地存储的照片（检查路径特征）
    var isLocalStored: Bool {
        // 检查是否包含我们的路径特征
        // 旧数据格式：/var/.../Documents/Photos/xxx.jpg
        // 新数据格式：/Photos/xxx.jpg
        return localIdentifier.contains("Documents/Photos/") || localIdentifier.starts(with: "/Photos/")
    }

    /// 获取位置信息
    var location: CLLocation? {
        guard let lat = latitude, let lon = longitude else {
            return nil
        }
        return CLLocation(latitude: lat, longitude: lon)
    }

    /// 计算拍摄时的宝宝年龄
    func babyAge(birthDate: Date) -> AgeInfo {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: birthDate, to: captureDate)
        let totalDays = max(0, components.day ?? 0)

        let milestone = KeyMilestone(rawValue: totalDays)
        let isMilestone = milestone != nil
        let months = totalDays / 30

        return AgeInfo(days: totalDays, months: months, isMilestone: isMilestone, milestone: milestone)
    }
}

