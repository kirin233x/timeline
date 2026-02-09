//
//  PhotoImportView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI
import PhotosUI

struct PhotoImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var timeline: Timeline
    @StateObject private var viewModel = PhotoImportViewModel()

    @State private var showingPhotoPicker = true

    var onComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                // 主内容
                mainContent

                // 里程碑发现动画
                if viewModel.isShowingMilestoneAnimation,
                   let milestone = viewModel.currentMilestoneAnimation {
                    milestoneAnimationOverlay(milestone)
                }
            }
            .navigationTitle("导入照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.phase == .selecting || viewModel.phase == .completed || viewModel.phase == .cancelled {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.canCancel {
                        Button("停止导入", role: .destructive) {
                            viewModel.cancelImport()
                        }
                    }
                }
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $viewModel.selectedItems,
                maxSelectionCount: 100,
                matching: .images
            )
            .onChange(of: viewModel.selectedItems) { _, newValue in
                if !newValue.isEmpty && viewModel.phase == .selecting {
                    viewModel.startImport(to: timeline, context: modelContext)
                }
            }
            .onChange(of: viewModel.phase) { _, newPhase in
                if newPhase == .completed {
                    // 延迟后自动关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete?()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.canCancel)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.phase {
        case .selecting:
            selectingView

        case .importing, .processing:
            importingView

        case .completed:
            completedView

        case .cancelled:
            cancelledView
        }
    }

    // MARK: - Selecting View

    private var selectingView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("选择要导入的照片")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                showingPhotoPicker = true
            } label: {
                Label("选择照片", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Importing View

    private var importingView: some View {
        VStack(spacing: 32) {
            // 进度圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: viewModel.progress)

                VStack(spacing: 4) {
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(viewModel.currentIndex)/\(viewModel.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 状态文本
            VStack(spacing: 8) {
                Text(viewModel.progressText)
                    .font(.headline)

                if viewModel.phase == .processing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // 已发现的里程碑
            if !viewModel.discoveredMilestones.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("发现 \(viewModel.discoveredMilestones.count) 个里程碑")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.discoveredMilestones) { discovered in
                                MilestoneChip(milestone: discovered.milestone)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
            }

            Spacer()

            // 提示
            Text("导入过程中请勿关闭应用")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
        .padding(.top, 60)
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            .transition(.scale.combined(with: .opacity))

            VStack(spacing: 8) {
                Text("导入完成")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("成功导入 \(viewModel.savedPhotos.count) 张照片")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !viewModel.discoveredMilestones.isEmpty {
                    Text("发现 \(viewModel.discoveredMilestones.count) 个里程碑")
                        .font(.subheadline)
                        .foregroundStyle(.pink)
                }
            }
        }
        .animation(.spring(duration: 0.5), value: viewModel.phase)
    }

    // MARK: - Cancelled View

    private var cancelledView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("导入已取消")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("已导入 \(viewModel.savedPhotos.count) 张照片")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                dismiss()
            } label: {
                Text("关闭")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Milestone Animation Overlay

    private func milestoneAnimationOverlay(_ discovered: DiscoveredMilestone) -> some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // 里程碑卡片
            VStack(spacing: 20) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 10)

                    Image(systemName: discovered.milestone.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                .scaleEffect(viewModel.isShowingMilestoneAnimation ? 1 : 0.5)
                .animation(.spring(duration: 0.5, bounce: 0.4), value: viewModel.isShowingMilestoneAnimation)

                // 文字
                VStack(spacing: 8) {
                    Text("发现里程碑")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(discovered.milestone.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(DateCalculator.formatDate(discovered.date))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(viewModel.isShowingMilestoneAnimation ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.2), value: viewModel.isShowingMilestoneAnimation)

                // 星星装饰
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        Image(systemName: "sparkle")
                            .foregroundStyle(.yellow)
                    }
                }
                .opacity(viewModel.isShowingMilestoneAnimation ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.4), value: viewModel.isShowingMilestoneAnimation)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .scaleEffect(viewModel.isShowingMilestoneAnimation ? 1 : 0.8)
            .animation(.spring(duration: 0.5), value: viewModel.isShowingMilestoneAnimation)
        }
        .transition(.opacity)
    }
}

// MARK: - Milestone Chip

struct MilestoneChip: View {
    let milestone: Milestone

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: milestone.icon)
                .font(.caption)

            Text(milestone.title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.pink)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.pink.opacity(0.15))
        )
    }
}

#Preview {
    PhotoImportView(timeline: Timeline(title: "测试", baseDate: Date()))
}
