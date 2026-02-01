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

        if months > 0 {
            let remainingDays = days - (months * 30)
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
