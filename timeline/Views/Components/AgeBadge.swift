//
//  AgeBadge.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI

struct AgeBadge: View {
    let ageInfo: AgeInfo

    var body: some View {
        VStack(spacing: 4) {
            if ageInfo.isMilestone, let milestone = ageInfo.milestone {
                // 关键里程碑样式
                Image(systemName: milestone.icon)
                    .font(.title3)
                    .foregroundStyle(AppColor.milestone)

                Text(ageInfo.displayText)
                    .font(.headline)
                    .foregroundStyle(AppColor.milestone)

                Text(ageInfo.subtitleText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                // 普通日期样式
                Text(ageInfo.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(ageInfo.subtitleText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ageInfo.isMilestone ? AppColor.milestone.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ageInfo.isMilestone ? AppColor.milestone : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        AgeBadge(ageInfo: AgeInfo(days: 0, months: 0, isMilestone: true, milestone: .birth))
        AgeBadge(ageInfo: AgeInfo(days: 30, months: 1, isMilestone: true, milestone: .fullMoon))
        AgeBadge(ageInfo: AgeInfo(days: 100, months: 3, isMilestone: true, milestone: .day100))
        AgeBadge(ageInfo: AgeInfo(days: 15, months: 0, isMilestone: false, milestone: nil))
        AgeBadge(ageInfo: AgeInfo(days: 60, months: 2, isMilestone: false, milestone: nil))
    }
    .padding()
}
