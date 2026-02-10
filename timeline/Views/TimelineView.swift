//
//  TimelineView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI
import SwiftData
import PhotosUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TimelineViewModel()

    var timeline: Timeline?
    @Query private var babies: [Baby]

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedPhoto: TimelinePhoto?
    @State private var selectedPhotoIndex: Int = 0
    @State private var selectedSection: TimelineSection?
    @State private var showingPhotoPicker = false
    @State private var showingPhotoImport = false
    @State private var showingDeleteAlert = false
    @State private var showingClearAlert = false
    @State private var showingMilestoneEditor = false
    @State private var photoToDelete: TimelinePhoto?
    @State private var isProcessingPhotos = false

    private var currentTimeline: Timeline? {
        if let timeline = timeline {
            return timeline
        }
        return nil
    }

    private var currentBaby: Baby? {
        babies.first
    }

    private var hasContent: Bool {
        currentTimeline != nil || currentBaby != nil
    }

    private var sectionsNotEmpty: Bool {
        !viewModel.timelineSections.isEmpty
    }

    // 获取当前section的所有照片用于浏览
    private var photosForBrowsing: [TimelinePhoto] {
        if let section = selectedSection {
            return section.photos
        }
        return viewModel.timelineSections.flatMap { $0.photos }
    }

    // 主题颜色
    private var themeColor: Color {
        if let timeline = currentTimeline {
            return Color(hex: timeline.color)
        }
        return .pink
    }

    var body: some View {
        ZStack {
            if let timeline = currentTimeline {
                mainContentForTimeline(timeline)
            } else if let baby = currentBaby {
                mainContent(for: baby)
            } else {
                emptyState
            }
        }
        .navigationTitle(currentTimeline?.title ?? currentBaby?.name ?? "时间线")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if hasContent {
                    Menu {
                        // 添加照片
                        Section {
                            Button {
                                showingPhotoImport = true
                            } label: {
                                Label("批量导入", systemImage: "square.and.arrow.down.on.square")
                            }

                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
                                Label("快速添加", systemImage: "plus.circle")
                            }
                        }

                        // 编辑里程碑
                        if let timeline = currentTimeline {
                            Section {
                                Button {
                                    showingMilestoneEditor = true
                                } label: {
                                    Label("编辑里程碑", systemImage: "star.circle")
                                }
                            }
                        }

                        // 清空
                        if sectionsNotEmpty {
                            Section {
                                Button(role: .destructive) {
                                    showingClearAlert = true
                                } label: {
                                    Label("清空时间线", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItems) { oldValue, newValue in
            guard !isProcessingPhotos,
                  !newValue.isEmpty,
                  newValue.count != oldValue.count else {
                return
            }

            isProcessingPhotos = true
            Task {
                await handlePhotoSelection(newValue)
                isProcessingPhotos = false
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            EnhancedPhotoDetailView(
                photos: photosForBrowsing,
                initialIndex: photosForBrowsing.firstIndex(where: { $0.id == photo.id }) ?? 0,
                baby: babies.first,
                timeline: currentTimeline
            )
        }
        .sheet(isPresented: $showingPhotoImport) {
            if let timeline = currentTimeline {
                PhotoImportView(timeline: timeline) {
                    viewModel.loadTimeline(timeline: timeline)
                }
            }
        }
        .sheet(isPresented: $showingMilestoneEditor) {
            if let timeline = currentTimeline {
                MilestoneEditorView(timeline: timeline)
            }
        }
        .alert("删除照片", isPresented: .constant(photoToDelete != nil && showingDeleteAlert)) {
            Button("取消", role: .cancel) {
                photoToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
                photoToDelete = nil
            }
        } message: {
            Text("确定要删除这张照片吗？")
        }
        .alert("清空时间线", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) {
                showingClearAlert = false
            }
            Button("清空", role: .destructive) {
                if let timeline = currentTimeline {
                    clearTimeline(for: timeline)
                } else if let baby = currentBaby {
                    clearTimeline(for: baby)
                }
                showingClearAlert = false
            }
        } message: {
            Text("确定要删除所有照片吗？此操作不可恢复。")
        }
        .task {
            await initialize()
        }
    }

    @ViewBuilder
    private func mainContent(for baby: Baby) -> some View {
        if viewModel.isLoading {
            ProgressView("加载中...")
        } else if viewModel.timelineSections.isEmpty {
            emptyTimelineState(for: baby)
        } else {
            timelineList
        }
    }

    @ViewBuilder
    private func mainContentForTimeline(_ timeline: Timeline) -> some View {
        if viewModel.isLoading {
            ProgressView("加载中...")
        } else if viewModel.timelineSections.isEmpty {
            emptyTimelineStateForTimeline(timeline)
        } else {
            timelineList
        }
    }

    private var timelineList: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // 连续的垂直时间线
                continuousTimelineLine
                    .padding(.leading, 30)

                // 时间线内容
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(viewModel.timelineSections.enumerated()), id: \.element.id) { index, section in
                        TimelineSectionView(
                            section: section,
                            onPhotoTap: { photo in
                                selectedSection = section
                                selectedPhoto = photo
                            },
                            onPhotoLongPress: { photo in
                                photoToDelete = photo
                                showingDeleteAlert = true
                            },
                            onPhotoTapWithIndex: { photo, _ in
                                selectedSection = section
                                selectedPhoto = photo
                            },
                            themeColor: themeColor
                        )
                        .staggered(index: index)
                        .padding(.bottom, index == viewModel.timelineSections.count - 1 ? 32 : 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .refreshable {
            if let timeline = currentTimeline {
                viewModel.loadTimeline(timeline: timeline)
            } else if let baby = currentBaby {
                viewModel.loadTimeline(baby: baby)
            }
        }
    }

    private var continuousTimelineLine: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [themeColor.opacity(0.4), themeColor.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .frame(height: proxy.size.height)
        }
    }

    private func clearTimeline(for baby: Baby) {
        guard let photos = baby.photos, !photos.isEmpty else { return }

        for photo in photos {
            if photo.isLocalStored {
                PhotoStorageService.shared.deletePhoto(at: photo.localPath)
            }
            modelContext.delete(photo)
        }

        try? modelContext.save()
        viewModel.loadTimeline(baby: baby)
    }

    private func clearTimeline(for timeline: Timeline) {
        guard !timeline.photos.isEmpty else { return }

        for photo in timeline.photos {
            if photo.isLocalStored {
                PhotoStorageService.shared.deletePhoto(at: photo.localPath)
            }
            modelContext.delete(photo)
        }

        try? modelContext.save()
        viewModel.loadTimeline(timeline: timeline)
    }

    private func deletePhoto(_ photo: TimelinePhoto) {
        if photo.isLocalStored {
            PhotoStorageService.shared.deletePhoto(at: photo.localPath)
        }
        modelContext.delete(photo)

        try? modelContext.save()
        viewModel.deletePhoto(photo, context: modelContext)
    }

    private func emptyTimelineState(for baby: Baby) -> some View {
        ContentUnavailableView {
            Label("还没有照片", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("点击右上角菜单添加宝宝照片，开始记录成长时光")
        } actions: {
            Button("添加照片") {
                showingPhotoPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .images
        )
    }

    private func emptyTimelineStateForTimeline(_ timeline: Timeline) -> some View {
        ContentUnavailableView {
            Label("还没有照片", systemImage: "photo.on.rectangle.angled")
                .foregroundStyle(themeColor)
        } description: {
            Text("点击右上角菜单添加照片，开始记录美好时光")
        } actions: {
            HStack(spacing: 16) {
                Button {
                    showingPhotoImport = true
                } label: {
                    Label("批量导入", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.bordered)
                .tint(themeColor)

                Button("快速添加") {
                    showingPhotoPicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(themeColor)
            }
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 10,
            matching: .images
        )
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有宝宝档案", systemImage: "heart.fill")
        } description: {
            Text("创建宝宝档案，开始记录美好时光")
        } actions: {
            NavigationLink(destination: OnboardingView()) {
                Text("创建档案")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func initialize() async {
        await PhotoService.shared.requestAuthorization()

        if let timeline = currentTimeline {
            viewModel.loadTimeline(timeline: timeline)
        } else if let baby = currentBaby {
            viewModel.loadTimeline(baby: baby)
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        let photos = await PhotoStorageService.shared.savePhotos(from: items)

        if !photos.isEmpty {
            if let timeline = currentTimeline {
                await viewModel.addSavedPhotos(photos: photos, to: timeline, context: modelContext)
            } else if let baby = currentBaby {
                await viewModel.addSavedPhotos(photos: photos, to: baby, context: modelContext)
            }
        }

        selectedPhotoItems = []
    }
}

#Preview {
    NavigationStack {
        TimelineView()
    }
    .modelContainer(for: [Baby.self, TimelinePhoto.self, Timeline.self], inMemory: true)
}
