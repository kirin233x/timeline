//
//  OnboardingView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI
import SwiftData
import PhotosUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OnboardingViewModel()

    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var avatarImage: UIImage?
    @State private var selectedPhotos: [SavedPhoto] = []
    @State private var isLoadingPhotos = false
    @State private var isProcessingPhotos = false  // 防止重复处理
    @State private var processedPhotoIds: Set<String> = []  // 记录已处理的照片ID，防止重复

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // 标题
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.pink, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("创建宝宝成长档案")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    // 头像选择
                    VStack(spacing: 12) {
                        Text("宝宝头像")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                            ZStack {
                                if let image = avatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                                .shadow(color: .black.opacity(0.1), radius: 3)
                                        )
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "camera.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.blue)
                                                Text("选择头像")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        )
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // 表单字段
                    VStack(spacing: 20) {
                        // 昵称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("宝宝昵称")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            TextField("输入宝宝的昵称", text: $viewModel.babyName)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                        }

                        // 出生日期
                        VStack(alignment: .leading, spacing: 8) {
                            Text("出生日期")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            DatePicker("", selection: $viewModel.birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }

                    // 选择照片
                    VStack(spacing: 12) {
                        Text("选择初始照片（可选）")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 10, matching: .images) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("从相册选择照片")
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    if !selectedPhotos.isEmpty {
                                        Text("已选择 \(selectedPhotos.count) 张")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("最多可选择 10 张")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .onChange(of: photoPickerItems) { oldValue, newValue in
                            print("🔍 onChange触发")
                            print("  旧数量: \(oldValue.count)")
                            print("  新数量: \(newValue.count)")

                            // 防止重复处理：检查是否正在处理
                            guard !isProcessingPhotos else {
                                print("  ⚠️ 正在处理中，跳过")
                                return
                            }

                            // 检查是否有新照片（排除已处理的）
                            let newIds = newValue.compactMap { $0.itemIdentifier }
                            let unprocessedIds = newIds.filter { !processedPhotoIds.contains($0) }

                            guard !unprocessedIds.isEmpty else {
                                print("  ⚠️ 所有照片都已处理，跳过")
                                return
                            }

                            print("  ✅ 发现 \(unprocessedIds.count) 张新照片")
                            isProcessingPhotos = true
                            Task {
                                await loadPhotos(from: newValue)
                                isProcessingPhotos = false
                                print("  ✅ 处理完成")
                            }
                        }

                        // 已选择照片预览
                        if !selectedPhotos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 8) {
                                    ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                                        Image(uiImage: photo.image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }

                    // 错误信息
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // 创建按钮
                    Button(action: {
                        viewModel.selectedPhotos = selectedPhotos
                        if let baby = viewModel.createBaby(context: modelContext) {
                            // 创建成功
                        }
                    }) {
                        HStack {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("创建档案")
                                    .fontWeight(.semibold)
                                    .font(.body)
                                Image(systemName: "arrow.right")
                                    .font(.body)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.isValid ? Color.blue : Color.gray)
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(!viewModel.isValid || viewModel.isProcessing)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("欢迎")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: avatarPickerItem) { oldValue, newValue in
                // 避免重复处理
                if newValue != oldValue {
                    Task {
                        await loadAvatar(from: newValue)
                    }
                }
            }
        }
    }

    private func loadAvatar(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        if let savedPhoto = await PhotoStorageService.shared.savePhoto(from: item) {
            avatarImage = savedPhoto.image
            viewModel.selectedAvatarLocalIdentifier = savedPhoto.localPath
            print("已选择头像: \(savedPhoto.localPath)")
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        print("📸 loadPhotos被调用，传入 \(items.count) 个项目")
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

        // 只处理未处理过的照片
        let unprocessedItems = items.filter { item in
            guard let id = item.itemIdentifier else { return false }
            return !processedPhotoIds.contains(id)
        }

        guard !unprocessedItems.isEmpty else {
            print("  ⚠️ 没有新照片需要处理")
            return
        }

        print("📸 开始处理 \(unprocessedItems.count) 张新照片")

        // 并发保存照片，提高性能
        let photos = await PhotoStorageService.shared.savePhotos(from: unprocessedItems)
        print("📸 保存完成，得到 \(photos.count) 张照片")

        // 标记这些照片为已处理
        for item in unprocessedItems {
            if let id = item.itemIdentifier {
                processedPhotoIds.insert(id)
            }
        }

        // 追加新照片（不清空旧的）
        selectedPhotos.append(contentsOf: photos)

        print("📸 selectedPhotos现在有 \(selectedPhotos.count) 张照片")
        for (index, photo) in photos.enumerated() {
            print("新照片 \(index + 1): \(photo.localPath)")
            if let exifDate = photo.exifData?.dateTimeOriginal {
                print("  EXIF: \(exifDate)")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Baby.self, TimelinePhoto.self], inMemory: true)
}
