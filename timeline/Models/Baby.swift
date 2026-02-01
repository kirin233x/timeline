//
//  Baby.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftData

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var avatarLocalIdentifier: String?
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \TimelinePhoto.baby)
    var photos: [TimelinePhoto]?

    init(name: String, birthDate: Date, avatarLocalIdentifier: String? = nil) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.avatarLocalIdentifier = avatarLocalIdentifier
        self.createdAt = Date()
        self.photos = []
    }

    /// 计算指定日期的年龄
    func age(at date: Date) -> AgeInfo {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: birthDate, to: date)
        let totalDays = max(0, components.day ?? 0)

        // 检查是否是关键里程碑
        let milestone = KeyMilestone(rawValue: totalDays)
        let isMilestone = milestone != nil

        // 计算月数（按30天计算）
        let months = totalDays / 30

        return AgeInfo(days: totalDays, months: months, isMilestone: isMilestone, milestone: milestone)
    }

    /// 判断是否为新生儿（0-30天）
    var isNewborn: Bool {
        let days = age(at: Date()).days
        return days <= 30
    }

    /// 获取当前年龄
    var currentAge: AgeInfo {
        return age(at: Date())
    }
}
