//
//  MilestoneEditorView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI

struct MilestoneEditorView: View {
    @Bindable var timeline: Timeline
    @Environment(\.dismiss) private var dismiss

    @State private var milestones: [Milestone] = []
    @State private var showingAddMilestone = false
    @State private var editingMilestone: Milestone?
    @State private var hasChanges = false

    var body: some View {
        NavigationStack {
            List {
                // 说明
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("里程碑是时间线上的重要时刻")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("照片拍摄日期与里程碑匹配时，将特别标记显示")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 里程碑列表
                Section("里程碑") {
                    ForEach(milestones.sorted(by: { $0.days < $1.days })) { milestone in
                        MilestoneRowView(milestone: milestone) {
                            editingMilestone = milestone
                        }
                    }
                    .onDelete(perform: deleteMilestones)

                    Button {
                        showingAddMilestone = true
                    } label: {
                        Label("添加里程碑", systemImage: "plus.circle.fill")
                    }
                }

                // 预设模板
                Section("快速添加") {
                    ForEach(MilestoneTemplate.allCases) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(template.color)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .foregroundStyle(.primary)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                // 重置
                Section {
                    Button(role: .destructive) {
                        resetToDefault()
                    } label: {
                        Label("恢复默认里程碑", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("编辑里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMilestones()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                MilestoneFormView(milestone: nil) { newMilestone in
                    milestones.append(newMilestone)
                    hasChanges = true
                }
            }
            .sheet(item: $editingMilestone) { milestone in
                MilestoneFormView(milestone: milestone) { updatedMilestone in
                    if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
                        milestones[index] = updatedMilestone
                        hasChanges = true
                    }
                }
            }
            .onAppear {
                milestones = timeline.getMilestones()
            }
        }
    }

    private func deleteMilestones(at offsets: IndexSet) {
        let sortedMilestones = milestones.sorted(by: { $0.days < $1.days })
        let idsToDelete = offsets.map { sortedMilestones[$0].id }
        milestones.removeAll { idsToDelete.contains($0.id) }
        hasChanges = true
    }

    private func saveMilestones() {
        timeline.milestonesData = Timeline.encodeMilestones(milestones)
    }

    private func resetToDefault() {
        milestones = Milestone.defaultMilestones
        hasChanges = true
    }

    private func applyTemplate(_ template: MilestoneTemplate) {
        let newMilestones = template.milestones
        for milestone in newMilestones {
            if !milestones.contains(where: { $0.days == milestone.days }) {
                milestones.append(milestone)
            }
        }
        hasChanges = true
    }
}

// MARK: - Milestone Row View

struct MilestoneRowView: View {
    let milestone: Milestone
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: milestone.icon)
                        .foregroundStyle(.pink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(formatDays(milestone.days))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatDays(_ days: Int) -> String {
        if days == 0 { return "起始日" }
        if days < 30 { return "第 \(days) 天" }
        if days < 365 {
            let months = days / 30
            let remainingDays = days % 30
            if remainingDays == 0 {
                return "\(months) 个月"
            }
            return "\(months) 个月 \(remainingDays) 天"
        }
        let years = days / 365
        let remainingDays = days % 365
        if remainingDays == 0 {
            return "\(years) 年"
        }
        return "\(years) 年 \(remainingDays) 天"
    }
}

// MARK: - Milestone Form View

struct MilestoneFormView: View {
    @Environment(\.dismiss) private var dismiss

    let milestone: Milestone?
    let onSave: (Milestone) -> Void

    @State private var title: String = ""
    @State private var days: Int = 0
    @State private var selectedIcon: String = "star.fill"

    let icons = [
        "star.fill", "heart.fill", "moon.fill", "sun.max.fill",
        "flame.fill", "leaf.fill", "birthday.cake.fill", "gift.fill",
        "trophy.fill", "crown.fill", "figure.walk", "figure.run",
        "camera.fill", "photo.fill", "book.fill", "graduationcap.fill",
        "airplane", "car.fill", "house.fill", "tree.fill"
    ]

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && days >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("里程碑名称", text: $title)

                    Stepper(value: $days, in: 0...36500) {
                        HStack {
                            Text("天数")
                            Spacer()
                            Text("\(days) 天")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 快捷天数选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickDayButton(label: "7天", days: 7, selected: $days)
                            QuickDayButton(label: "30天", days: 30, selected: $days)
                            QuickDayButton(label: "100天", days: 100, selected: $days)
                            QuickDayButton(label: "半年", days: 182, selected: $days)
                            QuickDayButton(label: "1年", days: 365, selected: $days)
                            QuickDayButton(label: "2年", days: 730, selected: $days)
                            QuickDayButton(label: "3年", days: 1095, selected: $days)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("图标") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.pink.opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundStyle(selectedIcon == icon ? .pink : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 预览
                Section("预览") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundStyle(.pink)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(title.isEmpty ? "里程碑名称" : title)
                                .font(.headline)
                                .foregroundStyle(title.isEmpty ? .tertiary : .primary)

                            Text("第 \(days) 天")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(milestone == nil ? "添加里程碑" : "编辑里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let newMilestone = Milestone(
                            days: days,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            icon: selectedIcon
                        )
                        onSave(newMilestone)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let milestone = milestone {
                    title = milestone.title
                    days = milestone.days
                    selectedIcon = milestone.icon
                }
            }
        }
    }
}

// MARK: - Quick Day Button

struct QuickDayButton: View {
    let label: String
    let days: Int
    @Binding var selected: Int

    var body: some View {
        Button {
            selected = days
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected == days ? Color.pink : Color.gray.opacity(0.15))
                .foregroundStyle(selected == days ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Milestone Template

enum MilestoneTemplate: String, CaseIterable, Identifiable {
    case baby = "baby"
    case relationship = "relationship"
    case project = "project"
    case fitness = "fitness"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .baby: return "宝宝成长"
        case .relationship: return "恋爱纪念"
        case .project: return "项目进度"
        case .fitness: return "健身计划"
        }
    }

    var description: String {
        switch self {
        case .baby: return "出生、满月、百天、周岁..."
        case .relationship: return "纪念日、100天、周年..."
        case .project: return "启动、MVP、发布..."
        case .fitness: return "21天、3个月、半年..."
        }
    }

    var icon: String {
        switch self {
        case .baby: return "figure.and.child.holdinghands"
        case .relationship: return "heart.fill"
        case .project: return "checkmark.seal.fill"
        case .fitness: return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .baby: return .pink
        case .relationship: return .red
        case .project: return .blue
        case .fitness: return .green
        }
    }

    var milestones: [Milestone] {
        switch self {
        case .baby:
            return [
                Milestone(days: 0, title: "出生", icon: "star.fill"),
                Milestone(days: 7, title: "第7天", icon: "7.circle.fill"),
                Milestone(days: 30, title: "满月", icon: "moon.fill"),
                Milestone(days: 100, title: "百天", icon: "100.circle"),
                Milestone(days: 180, title: "半岁", icon: "6.circle.fill"),
                Milestone(days: 365, title: "周岁", icon: "birthday.cake.fill"),
                Milestone(days: 730, title: "2岁", icon: "2.circle.fill"),
                Milestone(days: 1095, title: "3岁", icon: "3.circle.fill")
            ]
        case .relationship:
            return [
                Milestone(days: 0, title: "在一起", icon: "heart.fill"),
                Milestone(days: 100, title: "100天", icon: "100.circle"),
                Milestone(days: 365, title: "1周年", icon: "gift.fill"),
                Milestone(days: 730, title: "2周年", icon: "heart.circle.fill"),
                Milestone(days: 1095, title: "3周年", icon: "crown.fill")
            ]
        case .project:
            return [
                Milestone(days: 0, title: "项目启动", icon: "flag.fill"),
                Milestone(days: 30, title: "第一个月", icon: "1.circle.fill"),
                Milestone(days: 90, title: "季度里程碑", icon: "chart.line.uptrend.xyaxis"),
                Milestone(days: 180, title: "半年评审", icon: "checkmark.seal.fill"),
                Milestone(days: 365, title: "项目周年", icon: "trophy.fill")
            ]
        case .fitness:
            return [
                Milestone(days: 0, title: "开始健身", icon: "figure.run"),
                Milestone(days: 21, title: "习惯养成", icon: "checkmark.circle.fill"),
                Milestone(days: 90, title: "3个月坚持", icon: "flame.fill"),
                Milestone(days: 180, title: "半年成果", icon: "medal.fill"),
                Milestone(days: 365, title: "一年蜕变", icon: "trophy.fill")
            ]
        }
    }
}

#Preview {
    MilestoneEditorView(timeline: Timeline(title: "测试", baseDate: Date()))
}
