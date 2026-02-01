//
//  AgeInfo.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation

struct AgeInfo {
    let days: Int
    let months: Int
    let isMilestone: Bool
    let milestone: MilestoneProtocol?  // 使用协议支持不同类型的里程碑

    var displayText: String {
        if isMilestone, let milestone = milestone {
            return milestone.displayName
        }

        let years = days / 365
        let remainingMonths = (days % 365) / 30
        let remainingDays = days % 30

        if years > 0 {
            // xx年xx月xx天
            if remainingMonths > 0 && remainingDays > 0 {
                return "\(years)年\(remainingMonths)个月\(remainingDays)天"
            } else if remainingMonths > 0 {
                return "\(years)年\(remainingMonths)个月"
            } else if remainingDays > 0 {
                return "\(years)年\(remainingDays)天"
            } else {
                return "\(years)年"
            }
        } else if months > 0 {
            // xx月xx天
            if remainingDays > 0 {
                return "\(months)个月\(remainingDays)天"
            } else {
                return "\(months)个月"
            }
        } else {
            return "第\(days)天"
        }
    }

    var subtitleText: String {
        if isMilestone, let milestone = milestone {
            return "第\(milestone.days)天"
        }
        return "第\(days)天"
    }
}

// 里程碑协议
protocol MilestoneProtocol {
    var days: Int { get }
    var displayName: String { get }
    var icon: String { get }
}

// 扩展KeyMilestone以符合协议
extension KeyMilestone: MilestoneProtocol {}
