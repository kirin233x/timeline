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
    @State private var showingControls = true
    @State private var showingEditNotes = false
    @State private var showingEditDate = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingSaveSuccess = false
    @State private var imageToShare: UIImage?

    // Swipe to dismiss
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

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

    init(photo: TimelinePhoto, baby: Baby? = nil, timeline: Timeline? = nil) {
        self.init(photos: [photo], initialIndex: 0, baby: baby, timeline: timeline)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // Photo carousel
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
                .offset(y: dragOffset.height)
                .scaleEffect(isDragging ? max(0.9, 1 - abs(dragOffset.height) / 1000) : 1)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if abs(value.translation.height) > abs(value.translation.width) {
                                isDragging = true
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            if value.translation.height > 100 {
                                dismiss()
                            } else {
                                withAnimation(.spring(duration: 0.3)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )

                // Top bar
                if showingControls {
                    VStack {
                        topBar
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Bottom info panel
                if showingControls {
                    VStack {
                        Spacer()
                        infoPanel
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Save success overlay
                if showingSaveSuccess {
                    saveSuccessOverlay
                }
            }
        }
        .statusBarHidden(!showingControls)
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
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingControls.toggle()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            // Page indicator
            if photos.count > 1 {
                Text("\(currentIndex + 1) / \(photos.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
            }

            Spacer()

            // Menu button
            Menu {
                shareSection
                editSection
                deleteSection
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 12) {
                // Notes
                if let notes = currentPhoto.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "note.text")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 14))

                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                    }
                    .padding(.horizontal, 16)
                }

                // Date and age
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text("拍摄时间")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white.opacity(0.6))

                        Text(viewModel.formattedDate)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)

                        dateSourceBadge
                    }

                    Spacer()

                    if let ageInfo = viewModel.ageInfo {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("年龄")
                                    .font(.system(size: 12))
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(.white.opacity(0.6))

                            Text(ageInfo.displayText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(ageInfo.isMilestone ? .pink : .white)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Location
                if let locationName = viewModel.locationName {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12))

                        Text(locationName)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                }

                // Camera info
                if let exif = viewModel.exifData, exif.cameraModel != nil {
                    HStack(spacing: 12) {
                        if let camera = exif.cameraModel {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10))
                                Text(camera)
                                    .font(.system(size: 11))
                            }
                        }

                        if let lens = exif.lensModel {
                            Text(lens)
                                .font(.system(size: 11))
                        }
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var dateSourceBadge: some View {
        Group {
            if currentPhoto.hasManualDate {
                Text("手动设置")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(4)
            } else if currentPhoto.exifDate != nil {
                Text("EXIF")
                    .font(.system(size: 10, weight: .medium))
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
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("已保存到相册")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))
        )
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
                        withAnimation(.spring(duration: 0.3)) {
                            showingSaveSuccess = true
                        }

                        try? await Task.sleep(for: .seconds(1.5))

                        withAnimation(.easeOut(duration: 0.2)) {
                            showingSaveSuccess = false
                        }
                    }
                }
            }
        }
    }

    private func deleteCurrentPhoto() {
        if currentPhoto.isLocalStored {
            PhotoStorageService.shared.deletePhoto(at: currentPhoto.localPath)
        }

        modelContext.delete(currentPhoto)
        try? modelContext.save()

        if photos.count <= 1 {
            dismiss()
        } else {
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
                                        withAnimation(.spring(duration: 0.3)) {
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
                            withAnimation(.spring(duration: 0.3)) {
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
