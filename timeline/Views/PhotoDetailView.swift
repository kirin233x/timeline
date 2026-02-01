//
//  PhotoDetailView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI
import QuickLook
import SwiftData

struct PhotoDetailView: View {
    let photo: TimelinePhoto
    let baby: Baby?

    @StateObject private var viewModel: PhotoDetailViewModel
    @State private var showQuickLook = false
    @State private var showEditDate = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(photo: TimelinePhoto, baby: Baby?) {
        self.photo = photo
        self.baby = baby
        _viewModel = StateObject(wrappedValue: PhotoDetailViewModel(photo: photo, baby: baby))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 照片
                    photoSection

                    // 基本信息
                    basicInfoSection

                    // 位置信息
                    if viewModel.hasLocation {
                        locationSection
                    }

                    // EXIF 信息
                    exifSection
                }
                .padding()
            }
            .navigationTitle("照片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showQuickLook = true }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }

                        if let baby = baby {
                            Button(action: { showEditDate = true }) {
                                Label("修改日期", systemImage: "calendar")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
        .sheet(isPresented: $showQuickLook) {
            if let image = viewModel.fullImage {
                ShareSheet(activityItems: [image])
            }
        }
        .sheet(isPresented: $showEditDate) {
            if let baby = baby {
                PhotoDateEditView(
                    photo: photo,
                    baby: baby,
                    onDateChanged: { newDate in
                        photo.manualDate = newDate
                        try? modelContext.save()
                        dismiss()
                    },
                    onCancel: {
                        showEditDate = false
                    }
                )
            }
        }
    }

    private var photoSection: some View {
        VStack(spacing: 12) {
            if let image = viewModel.fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            } else if viewModel.isLoading {
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay {
                        ProgressView()
                    }
            } else {
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                    }
            }
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 拍摄时间
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("拍摄时间")
                        .font(.headline)

                    Spacer()

                    // 日期来源标签
                    if photo.hasManualDate {
                        Text("手动设置")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .cornerRadius(4)
                    } else if photo.exifDate != nil {
                        Text("EXIF")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    } else {
                        Text("资源日期")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.gray)
                            .cornerRadius(4)
                    }
                }

                Text(viewModel.formattedDate)
                    .font(.body)
                    .foregroundStyle(.secondary)

                // 如果没有 EXIF 日期，显示提示
                if photo.exifDate == nil && !photo.hasManualDate {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("此照片没有 EXIF 信息，可点击右上角菜单修改日期")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }

                // 宝宝年龄
                if let ageInfo = viewModel.ageInfo {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("宝宝年龄")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(ageInfo.displayText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            Divider()

            // EXIF 信息标题
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("拍摄参数")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(Constants.cornerRadius)
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundStyle(.red)
                Text("拍摄地点")
                    .font(.headline)
            }

            if let location = photo.location, let locationName = viewModel.locationName {
                PhotoMapView(location: location, locationName: locationName)
            } else if viewModel.isLoading {
                ProgressView("加载位置信息...")
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(Constants.cornerRadius)
    }

    private var exifSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            EXIFInfoView(exifData: viewModel.exifData)
        }
    }
}

// 用于分享的简单 Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let baby = Baby(name: "测试宝宝", birthDate: Date().addingTimeInterval(-30*24*3600))
    let photo = TimelinePhoto(
        localIdentifier: "test",
        exifDate: Date(),
        assetDate: Date(),
        baby: baby
    )
    return PhotoDetailView(photo: photo, baby: baby)
}
