//
//  EnhancedPhotoDetailView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI
import Photos

struct EnhancedPhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let photos: [TimelinePhoto]
    let initialIndex: Int
    let baby: Baby?
    let timeline: Timeline?

    @State private var currentIndex: Int
    @State private var showingFullScreen = false
    @State private var showingEditNotes = false
    @State private var showingEditDate = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingSaveSuccess = false
    @State private var imageToShare: UIImage?

    @StateObject private var viewModel: PhotoDetailViewModel

    private var currentPhoto: TimelinePhoto {
        photos[currentIndex]
    }

    init(photos: [TimelinePhoto], initialIndex: Int = 0, baby: Baby? = nil, timeline: Timeline? = nil) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.baby = baby
        self.timeline = timeline
        _currentIndex = State(initialValue: initialIndex)

        let photo = photos[initialIndex]
        _viewModel = StateObject(wrappedValue: PhotoDetailViewModel(photo: photo, baby: baby))
    }

    // 单张照片的便捷初始化
    init(photo: TimelinePhoto, baby: Baby? = nil, timeline: Timeline? = nil) {
        self.init(photos: [photo], initialIndex: 0, baby: baby, timeline: timeline)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()

                    // 照片轮播
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            ZoomablePhotoView(photo: photo)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _, newIndex in
                        let photo = photos[newIndex]
                        viewModel.photo = photo
                        Task {
                            await viewModel.loadData()
                        }
                    }

                    // 底部信息面板
                    if !showingFullScreen {
                        VStack {
                            Spacer()
                            infoPanel
                        }
                    }

                    // 页码指示器
                    if photos.count > 1 && !showingFullScreen {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(currentIndex + 1)/\(photos.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if !showingFullScreen {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            shareSection
                            editSection
                            deleteSection
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingEditNotes) {
                NotesEditorView(photo: currentPhoto) {
                    try? modelContext.save()
                }
            }
            .sheet(isPresented: $showingEditDate) {
                if let baby = baby {
                    PhotoDateEditView(
                        photo: currentPhoto,
                        baby: baby,
                        onDateChanged: { newDate in
                            currentPhoto.manualDate = newDate
                            try? modelContext.save()
                            showingEditDate = false
                        },
                        onCancel: {
                            showingEditDate = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = imageToShare {
                    ShareSheet(activityItems: [image])
                }
            }
            .alert("删除照片", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteCurrentPhoto()
                }
            } message: {
                Text("确定要删除这张照片吗？此操作不可撤销。")
            }
            .overlay {
                if showingSaveSuccess {
                    saveSuccessOverlay
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingFullScreen.toggle()
                }
            }
        }
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(spacing: 0) {
            // 拖动指示器
            Capsule()
                .fill(Color.white.opacity(0.5))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 备注
                    if let notes = currentPhoto.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(.yellow)
                                Text("备注")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)

                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal)
                    }

                    // 日期与年龄
                    HStack(spacing: 24) {
                        // 日期
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text("拍摄时间")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white.opacity(0.7))

                            Text(viewModel.formattedDate)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)

                            // 日期来源
                            dateSourceBadge
                        }

                        Spacer()

                        // 年龄
                        if let ageInfo = viewModel.ageInfo {
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("年龄")
                                        .font(.caption)
                                    Image(systemName: "heart.fill")
                                }
                                .foregroundStyle(.white.opacity(0.7))

                                Text(ageInfo.displayText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(ageInfo.isMilestone ? .pink : .white)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // 位置
                    if let locationName = viewModel.locationName {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.red)

                            Text(locationName)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal)
                    }

                    // EXIF 简要信息
                    if let exif = viewModel.exifData, exif.cameraModel != nil {
                        HStack(spacing: 16) {
                            if let camera = exif.cameraModel {
                                HStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                    Text(camera)
                                        .font(.caption)
                                }
                            }

                            if let lens = exif.lensModel {
                                Text(lens)
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(maxHeight: 200)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var dateSourceBadge: some View {
        Group {
            if currentPhoto.hasManualDate {
                Text("手动设置")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(4)
            } else if currentPhoto.exifDate != nil {
                Text("EXIF")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(4)
            }
        }
    }

    // MARK: - Menu Sections

    @ViewBuilder
    private var shareSection: some View {
        Section {
            Button {
                Task {
                    imageToShare = await PhotoService.shared.fetchFullImage(for: currentPhoto.localIdentifier)
                    showingShareSheet = true
                }
            } label: {
                Label("分享", systemImage: "square.and.arrow.up")
            }

            Button {
                Task {
                    await saveToPhotoLibrary()
                }
            } label: {
                Label("保存到相册", systemImage: "square.and.arrow.down")
            }
        }
    }

    @ViewBuilder
    private var editSection: some View {
        Section {
            Button {
                showingEditNotes = true
            } label: {
                Label(currentPhoto.notes == nil ? "添加备注" : "编辑备注", systemImage: "note.text")
            }

            if baby != nil {
                Button {
                    showingEditDate = true
                } label: {
                    Label("修改日期", systemImage: "calendar")
                }
            }
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("删除照片", systemImage: "trash")
            }
        }
    }

    // MARK: - Save Success Overlay

    private var saveSuccessOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("已保存到相册")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions

    private func saveToPhotoLibrary() async {
        guard let image = await PhotoService.shared.fetchFullImage(for: currentPhoto.localIdentifier) else {
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                if success {
                    Task { @MainActor in
                        withAnimation {
                            showingSaveSuccess = true
                        }

                        try? await Task.sleep(for: .seconds(1.5))

                        withAnimation {
                            showingSaveSuccess = false
                        }
                    }
                }
            }
        }
    }

    private func deleteCurrentPhoto() {
        // 删除本地文件
        if currentPhoto.isLocalStored {
            PhotoStorageService.shared.deletePhoto(at: currentPhoto.localPath)
        }

        // 删除数据库记录
        modelContext.delete(currentPhoto)
        try? modelContext.save()

        // 如果删除后没有照片了，关闭视图
        if photos.count <= 1 {
            dismiss()
        } else {
            // 调整索引
            if currentIndex >= photos.count - 1 {
                currentIndex = max(0, photos.count - 2)
            }
        }
    }
}

// MARK: - Zoomable Photo View

struct ZoomablePhotoView: View {
    let photo: TimelinePhoto

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 5)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale <= 1 {
                                        withAnimation(.spring()) {
                                            scale = 1
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .task {
            image = await PhotoService.shared.fetchFullImage(for: photo.localIdentifier)
        }
    }
}

// MARK: - Notes Editor View

struct NotesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var photo: TimelinePhoto
    var onSave: () -> Void

    @State private var notes: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $notes)
                    .focused($isFocused)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))

                // 字数统计
                HStack {
                    Spacer()
                    Text("\(notes.count) / 500")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("编辑备注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        photo.notes = notes.isEmpty ? nil : notes
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                notes = photo.notes ?? ""
                isFocused = true
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    EnhancedPhotoDetailView(
        photo: TimelinePhoto(localIdentifier: "test", exifDate: Date(), assetDate: Date()),
        baby: nil
    )
}
