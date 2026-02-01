//
//  Timeline.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Timeline {
    var id: UUID
    var title: String  // 时间线标题，如"宝宝成长"、"恋爱纪念日"
    var baseDate: Date  // 基准日期（生日/纪念日等）
    var icon: String  // 图标名称
    var color: String  // 主题颜色（hex）
    var createdAt: Date
    var milestonesData: Data?  // 自定义里程碑数据（JSON编码）

    @Relationship(deleteRule: .cascade) var photos: [TimelinePhoto]

    init(title: String, baseDate: Date, icon: String = "heart.fill", color: String = "#FF69B4", milestones: [Milestone] = []) {
        self.id = UUID()
        self.title = title
        self.baseDate = baseDate
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.photos = []

        // 保存自定义里程碑
        if !milestones.isEmpty {
            self.milestonesData = Self.encodeMilestones(milestones)
        }
    }

    // 计算指定日期的年龄/天数
    func ageInfo(at date: Date) -> AgeInfo {
        let calendar = Calendar.current

        // 计算总天数
        let components = calendar.dateComponents([.day], from: baseDate, to: date)
        let totalDays = max(0, components.day ?? 0)

        // 计算月数（总天数 / 30）
        let months = totalDays / 30

        // 检查是否是关键里程碑
        let milestones = getMilestones()
        let isMilestone = milestones.contains { $0.days == totalDays }

        let milestone = milestones.first { $0.days == totalDays }

        return AgeInfo(days: totalDays, months: months, isMilestone: isMilestone, milestone: milestone)
    }

    // 获取里程碑列表
    func getMilestones() -> [Milestone] {
        if let data = milestonesData, let milestones = Self.decodeMilestones(data) {
            return milestones
        }
        // 默认里程碑
        return Milestone.defaultMilestones
    }

    // 编码里程碑
    static func encodeMilestones(_ milestones: [Milestone]) -> Data {
        if let data = try? JSONEncoder().encode(milestones) {
            return data
        }
        return Data()
    }

    // 解码里程碑
    static func decodeMilestones(_ data: Data) -> [Milestone]? {
        if let milestones = try? JSONDecoder().decode([Milestone].self, from: data) {
            return milestones
        }
        return nil
    }
}

// 自定义里程碑模型
struct Milestone: Codable, Identifiable, Hashable, MilestoneProtocol {
    let id: UUID
    let days: Int
    let title: String
    let icon: String

    // MilestoneProtocol要求
    var displayName: String { title }

    init(days: Int, title: String, icon: String) {
        self.id = UUID()
        self.days = days
        self.title = title
        self.icon = icon
    }

    // 默认里程碑
    static let defaultMilestones = [
        Milestone(days: 0, title: "开始", icon: "star.fill"),
        Milestone(days: 7, title: "第7天", icon: "7.circle.fill"),
        Milestone(days: 30, title: "第30天", icon: "30.circle.fill"),
        Milestone(days: 100, title: "第100天", icon: "100.circle.fill"),
        Milestone(days: 365, title: "1周年", icon: "1.circle.fill")
    ]
}
