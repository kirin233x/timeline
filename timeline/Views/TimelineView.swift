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
    @StateObject private var photoService = PhotoService()

    @Query private var babies: [Baby]
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedPhoto: TimelinePhoto?
    @State private var showingPhotoPicker = false
    @State private var showingDeleteAlert = false
    @State private var photoToDelete: TimelinePhoto?
    @State private var isEditMode = false

    var body: some View {
        NavigationView {
            ZStack {
                if let baby = babies.first {
                    mainContent(for: baby)
                } else {
                    emptyState
                }
            }
            .navigationTitle("宝宝时间线")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !babies.isEmpty && !viewModel.timelineSections.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("清空时间线", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !babies.isEmpty {
                        HStack(spacing: 16) {
                            if !viewModel.timelineSections.isEmpty {
                                Button(action: {
                                    isEditMode.toggle()
                                }) {
                                    Image(systemName: isEditMode ? "checkmark" : "pencil")
                                        .foregroundStyle(isEditMode ? .blue : .primary)
                                }
                            }

                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
                                Image(systemName: "plus")
                                    .fontWeight(.semibold)
                            }
                            // onChange已移到第213行，避免重复注册
                        }
                    }
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo, baby: babies.first)
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
            .alert("清空时间线", isPresented: .constant(photoToDelete == nil && showingDeleteAlert)) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    if let baby = babies.first {
                        clearTimeline(for: baby)
                    }
                }
            } message: {
                Text("确定要删除所有照片吗？此操作不可恢复。")
            }
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

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.timelineSections) { section in
                    TimelineSectionView(section: section, isEditMode: isEditMode) { photo in
                        if isEditMode {
                            photoToDelete = photo
                            showingDeleteAlert = true
                        } else {
                            selectedPhoto = photo
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func clearTimeline(for baby: Baby) {
        guard let photos = baby.photos, !photos.isEmpty else { return }

        for photo in photos {
            // 删除本地文件
            if photo.isLocalStored {
                PhotoStorageService.shared.deletePhoto(at: photo.localPath)
            }
            // 删除数据库记录
            modelContext.delete(photo)
        }

        try? modelContext.save()
        viewModel.loadTimeline(baby: baby)
    }

    private func deletePhoto(_ photo: TimelinePhoto) {
        // 删除本地文件
        if photo.isLocalStored {
            PhotoStorageService.shared.deletePhoto(at: photo.localPath)
        }
        // 删除数据库记录
        modelContext.delete(photo)

        try? modelContext.save()

        // 重新加载时间线
        if let baby = babies.first {
            viewModel.loadTimeline(baby: baby)
        }
    }

    private func emptyTimelineState(for baby: Baby) -> some View {
        ContentUnavailableView {
            Label("还没有照片", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("点击右上角 + 号添加宝宝照片，开始记录成长时光")
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
        .onChange(of: selectedPhotoItems) { oldValue, newValue in
            Task {
                await handlePhotoSelection(newValue)
            }
        }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if !babies.isEmpty {
                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 10, matching: .images) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .onChange(of: selectedPhotoItems) { oldValue, newValue in
                    // 防止重复处理：只在数量变化且不为空时处理
                    guard !newValue.isEmpty, newValue.count != oldValue.count else {
                        return
                    }
                    Task {
                        await handlePhotoSelection(newValue)
                    }
                }
            }
        }
    }

    private func initialize() async {
        await photoService.requestAuthorization()

        if let baby = babies.first {
            viewModel.loadTimeline(baby: baby)
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        print("开始处理选择的 \(items.count) 个项目")

        // 并发保存照片到沙盒
        let photos = await PhotoStorageService.shared.savePhotos(from: items)

        print("准备添加 \(photos.count) 张照片到时间线")

        if !photos.isEmpty, let baby = babies.first {
            await viewModel.addSavedPhotos(photos: photos, to: baby, context: modelContext)
        }

        selectedPhotoItems = []
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: [Baby.self, TimelinePhoto.self], inMemory: true)
}
