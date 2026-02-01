import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - 工具类：图片存储管理
// 负责将头像图片保存到沙盒的 Documents/TimelineIcons 目录
struct ImageStorage {
    static let shared = ImageStorage()
    private let fileManager = FileManager.default
    
    private var iconsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let iconsDir = documentsDirectory.appendingPathComponent("TimelineIcons")
        
        if !fileManager.fileExists(atPath: iconsDir.path) {
            try? fileManager.createDirectory(at: iconsDir, withIntermediateDirectories: true)
        }
        return iconsDir
    }
    
    // 保存图片，返回带 local: 前缀的文件名
    func saveImage(_ image: UIImage) -> String? {
        // 使用 UUID 确保每次文件名都不同，这对于强制刷新 UI 至关重要
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = iconsDirectory.appendingPathComponent(fileName)
        
        // 压缩图片以减少空间占用
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        
        do {
            try data.write(to: fileURL)
            print("✅ 图片已保存到: \(fileName)")
            return "local:" + fileName
        } catch {
            print("❌ 图片保存失败: \(error)")
            return nil
        }
    }
    
    // 读取图片
    func loadImage(fileName: String) -> UIImage? {
        let cleanName = fileName.replacingOccurrences(of: "local:", with: "")
        let fileURL = iconsDirectory.appendingPathComponent(cleanName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // 删除图片
    func deleteImage(fileName: String) {
        guard fileName.hasPrefix("local:") else { return }
        let cleanName = fileName.replacingOccurrences(of: "local:", with: "")
        let fileURL = iconsDirectory.appendingPathComponent(cleanName)
        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - Timeline List View
struct TimelineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Timeline.createdAt, order: .reverse) private var timelines: [Timeline]
    
    @State private var showingCreateTimeline = false
    @State private var timelineToEdit: Timeline?
    @State private var selectedTimelineForNavigation: Timeline?

    var body: some View {
        NavigationStack {
            Group {
                if timelines.isEmpty {
                    emptyState
                } else {
                    timelineList
                }
            }
            .navigationTitle("我的时间线")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateTimeline = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCreateTimeline) {
                CreateTimelineView()
            }
            // 使用 item 形式的 sheet 确保编辑视图生命周期正确
            .sheet(item: $timelineToEdit) { timeline in
                CreateTimelineView(timeline: timeline)
            }
            .navigationDestination(item: $selectedTimelineForNavigation) { timeline in
                TimelineDetailView(timeline: timeline)
            }
        }
    }

    private var timelineList: some View {
        List {
            ForEach(timelines) { timeline in
                TimelineCardView(timeline: timeline) {
                    selectedTimelineForNavigation = timeline
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                // 🔥 关键修改：添加 .id(timeline.icon)
                // 这强制 SwiftUI 在图标路径改变时重新渲染整个卡片，从而重新加载本地图片
                .id(timeline.icon)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTimeline(timeline)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }

                    Button {
                        timelineToEdit = timeline
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
        .padding(.vertical, 8)
    }

    private func deleteTimeline(_ timeline: Timeline) {
        // 1. 删除关联的照片（这里假设你有 PhotoStorageService，如果没有请注释掉）
        for photo in timeline.photos {
            if photo.isLocalStored {
                // PhotoStorageService.shared.deletePhoto(at: photo.localPath)
            }
            modelContext.delete(photo)
        }
        
        // 2. 如果图标是本地图片，删除它
        if timeline.icon.hasPrefix("local:") {
            ImageStorage.shared.deleteImage(fileName: timeline.icon)
        }
        
        // 3. 删除时间线对象
        modelContext.delete(timeline)
        
        try? modelContext.save()
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("还没有时间线")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("创建你的第一个时间线，记录美好时光")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { showingCreateTimeline = true }) {
                Text("创建时间线")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Timeline Card View
struct TimelineCardView: View {
    let timeline: Timeline
    var onTap: () -> Void
    
    // 增加一个状态来存储加载后的图片，避免 body 重复读取 IO
    @State private var loadedImage: UIImage?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: timeline.color))
                        .frame(width: 60, height: 60)

                    // 图标显示逻辑
                    Group {
                        if timeline.icon.hasPrefix("local:") {
                            if let image = loadedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                // 加载占位或 loading
                                ProgressView()
                                    .tint(.white)
                            }
                        } else {
                            Image(systemName: timeline.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(timeline.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(timeline.photos.count) 张照片")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("起始日期: \(DateCalculator.formatShortDate(timeline.baseDate))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        // 视图加载时尝试读取图片
        .onAppear {
            loadImageIfNeeded()
        }
        // 当 icon 属性变化时（通过 id 刷新）再次读取
        .onChange(of: timeline.icon) { _, _ in
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        if timeline.icon.hasPrefix("local:") {
            // 异步加载以免卡顿列表滑动
            DispatchQueue.global(qos: .userInitiated).async {
                let image = ImageStorage.shared.loadImage(fileName: timeline.icon)
                DispatchQueue.main.async {
                    self.loadedImage = image
                }
            }
        } else {
            self.loadedImage = nil
        }
    }
}

// MARK: - Create / Edit Timeline View
struct CreateTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var timeline: Timeline?

    @State private var title: String
    @State private var baseDate: Date
    @State private var selectedIcon: String?
    @State private var selectedColor: String
    @State private var customIconImage: UIImage?
    @State private var showingIconPicker = false
    @State private var errorMessage: String?
    
    // 标记是否是新选择的图片
    @State private var isNewImageSelected = false

    let icons = ["heart.fill", "star.fill", "moon.fill", "sun.max.fill", "flame.fill", "leaf.fill", "droplet.fill", "wind"]
    let colors = ["#FF69B4", "#FF6347", "#FFD700", "#32CD32", "#00CED1", "#4169E1", "#9370DB", "#FF1493"]

    var isEditMode: Bool {
        timeline != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(timeline: Timeline? = nil) {
        self.timeline = timeline
        
        if let timeline = timeline {
            _title = State(initialValue: timeline.title)
            _baseDate = State(initialValue: timeline.baseDate)
            _selectedColor = State(initialValue: timeline.color)
            
            if timeline.icon.hasPrefix("local:") {
                _selectedIcon = State(initialValue: nil)
                // 同步加载编辑时的预览图
                if let image = ImageStorage.shared.loadImage(fileName: timeline.icon) {
                    _customIconImage = State(initialValue: image)
                }
            } else {
                _selectedIcon = State(initialValue: timeline.icon)
                _customIconImage = State(initialValue: nil)
            }
        } else {
            _title = State(initialValue: "")
            _baseDate = State(initialValue: Date())
            _selectedIcon = State(initialValue: "heart.fill")
            _selectedColor = State(initialValue: "#FF69B4")
            _customIconImage = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时间线标题").font(.headline)
                        TextField("例如：宝宝成长、恋爱纪念日", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("起始日期").font(.headline)
                        DatePicker("", selection: $baseDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择图标").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                            Button(action: { showingIconPicker = true }) {
                                ZStack {
                                    Circle()
                                        .fill(customIconImage != nil ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    if let image = customIconImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 2) {
                                            Image(systemName: "photo.on.rectangle.angled").font(.title3)
                                            Text("相册").font(.caption2)
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                    customIconImage = nil
                                    isNewImageSelected = false
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundStyle(selectedIcon == icon ? .blue : .primary)
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("主题颜色").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(Color(uiColor: .separator), lineWidth: 1))
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text(errorMessage).font(.caption).foregroundStyle(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button(action: saveTimeline) {
                        Text(isEditMode ? "保存修改" : "创建时间线")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .navigationTitle(isEditMode ? "编辑时间线" : "创建时间线")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .photosPicker(
            isPresented: $showingIconPicker,
            selection: Binding(
                get: { [] },
                set: { items in
                    if let item = items.first {
                        Task { await loadCustomIcon(from: item) }
                    }
                }
            ),
            maxSelectionCount: 1,
            matching: .images
        )
    }

    private func loadCustomIcon(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        customIconImage = cropToSquare(image)
        selectedIcon = nil
        isNewImageSelected = true // 标记选择了新图片
    }

    private func cropToSquare(_ image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let x = (image.size.width - size) / 2
        let y = (image.size.height - size) / 2
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, image.scale)
        image.draw(at: CGPoint(x: -x, y: -y))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage ?? image
    }

    private func saveTimeline() {
        guard isValid else { return }
        
        var finalIcon: String
        
        // 逻辑：
        // 1. 如果有 customIconImage，且是新选择的 -> 保存新文件
        // 2. 如果有 customIconImage，但不是新选择的（编辑模式原有的）-> 保持原路径（或者为了强制刷新，也可以重新保存）
        // 3. 如果 selectedIcon 不为空 -> 使用系统图标
        
        if let customImage = customIconImage {
            // 这里为了简单且确保刷新的稳定性，只要是自定义图片，我们都保存一份新的（新的UUID）
            // 这样 timeline.icon 字符串会变化，从而触发列表的 .id() 刷新
            // 虽然会增加一点点IO，但能保证UI 100% 刷新
            if let localPath = ImageStorage.shared.saveImage(customImage) {
                finalIcon = localPath
            } else {
                finalIcon = "heart.fill"
            }
        } else {
            finalIcon = selectedIcon ?? "heart.fill"
        }
        
        if let timeline = timeline {
            timeline.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            timeline.baseDate = baseDate
            
            // 如果图标确实变了（因为我们用了 UUID，所以图片只要保存就会变），删除旧图片
            if timeline.icon.hasPrefix("local:") && timeline.icon != finalIcon {
                ImageStorage.shared.deleteImage(fileName: timeline.icon)
            }
            
            timeline.icon = finalIcon
            timeline.color = selectedColor
            
            try? modelContext.save()
            dismiss()
        } else {
            let newTimeline = Timeline(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                baseDate: baseDate,
                icon: finalIcon,
                color: selectedColor
            )
            modelContext.insert(newTimeline)
            try? modelContext.save()
            dismiss()
        }
    }
}

// MARK: - Helper Extensions
struct TimelineDetailView: View {
    let timeline: Timeline
    var body: some View {
        TimelineView(timeline: timeline)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
