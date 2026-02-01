//
//  DateCalculator.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation

struct DateCalculator {
    /// 计算两个日期之间的天数
    static func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }

    /// 计算月数（按30天计算）
    static func monthsBetween(from startDate: Date, to endDate: Date) -> Int {
        let days = daysBetween(from: startDate, to: endDate)
        return days / 30
    }

    /// 格式化日期显示
    static func formatDate(_ date: Date, format: String = Constants.dateFormatDisplay) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    /// 格式化简短日期
    static func formatShortDate(_ date: Date) -> String {
        return formatDate(date, format: Constants.dateFormatShort)
    }

    /// 检查是否为关键里程碑
    static func isMilestoneDay(days: Int) -> Bool {
        return KeyMilestone(rawValue: days) != nil
    }

    /// 获取里程碑信息
    static func getMilestone(days: Int) -> KeyMilestone? {
        return KeyMilestone(rawValue: days)
    }
}
