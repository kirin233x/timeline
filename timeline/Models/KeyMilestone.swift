//
//  KeyMilestone.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import Foundation

enum KeyMilestone: Int, CaseIterable {
    case birth = 0
    case day7 = 7
    case fullMoon = 30
    case day100 = 100
    case firstYear = 365

    var displayName: String {
        switch self {
        case .birth:
            return "出生"
        case .day7:
            return "第7天"
        case .fullMoon:
            return "满月"
        case .day100:
            return "百天"
        case .firstYear:
            return "周岁"
        }
    }

    var icon: String {
        switch self {
        case .birth:
            return "star.fill"
        case .day7:
            return "7.circle.fill"
        case .fullMoon:
            return "moon.fill"
        case .day100:
            return "100.circle.fill"
        case .firstYear:
            return "crown.fill"
        }
    }

    var days: Int {
        return rawValue
    }
}
