import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Image Storage Helper
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

    func saveImage(_ image: UIImage) -> String? {
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = iconsDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        do {
            try data.write(to: fileURL)
            return "local:" + fileName
        } catch {
            return nil
        }
    }

    func loadImage(fileName: String) -> UIImage? {
        let cleanName = fileName.replacingOccurrences(of: "local:", with: "")
        let fileURL = iconsDirectory.appendingPathComponent(cleanName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

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
    @State private var showingSettings = false
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }

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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
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
        // 1. Delete associated photos and their local files
        for photo in timeline.photos {
            if photo.isLocalStored {
                PhotoStorageService.shared.deletePhoto(at: photo.localPath)
            }
            modelContext.delete(photo)
        }

        // 2. Delete icon if it's a local image
        if timeline.icon.hasPrefix("local:") {
            ImageStorage.shared.deleteImage(fileName: timeline.icon)
        }

        // 3. Delete the timeline object
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
                    .background(
                        LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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

    @State private var loadedImage: UIImage?

    private var themeColor: Color {
        Color(hex: timeline.color)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with theme color
                ZStack {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 56, height: 56)

                    if timeline.icon.hasPrefix("local:") {
                        if let image = loadedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    } else {
                        Image(systemName: timeline.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(timeline.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Label("\(timeline.photos.count)", systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.secondary)

                        Text(DateCalculator.formatShortDate(timeline.baseDate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Theme color indicator
                Circle()
                    .fill(themeColor)
                    .frame(width: 8, height: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: themeColor.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            loadImageIfNeeded()
        }
        .onChange(of: timeline.icon) { _, _ in
            loadImageIfNeeded()
        }
    }

    private func loadImageIfNeeded() {
        if timeline.icon.hasPrefix("local:") {
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
    @State private var isNewImageSelected = false

    let icons = [
        "heart.fill", "star.fill", "moon.fill", "sun.max.fill",
        "flame.fill", "leaf.fill", "camera.fill", "gift.fill",
        "graduationcap.fill", "airplane", "car.fill", "house.fill"
    ]

    let colors = [
        "#FF69B4", "#FF6347", "#FFD700", "#32CD32",
        "#00CED1", "#4169E1", "#9370DB", "#FF1493",
        "#20B2AA", "#778899", "#8B4513", "#2F4F4F"
    ]

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
                VStack(spacing: 28) {
                    // Preview card
                    previewCard

                    // Title input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("时间线标题")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("输入标题...", text: $title)
                            .font(.system(size: 17))
                            .padding(14)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("起始日期")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color(hex: selectedColor))

                            DatePicker("", selection: $baseDate, displayedComponents: .date)
                                .labelsHidden()

                            Spacer()
                        }
                        .padding(14)
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Icon selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("选择图标")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            // Custom photo button
                            Button(action: { showingIconPicker = true }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(customIconImage != nil ? Color(hex: selectedColor).opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
                                        .frame(height: 52)

                                    if let image = customIconImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 36, height: 36)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "photo")
                                            .font(.system(size: 20))
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
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
                                            .frame(height: 52)

                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                    }
                                }
                            }
                        }
                    }

                    // Color selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("主题颜色")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 44, height: 44)

                                        if selectedColor == color {
                                            Circle()
                                                .stroke(Color(uiColor: .systemBackground), lineWidth: 3)
                                                .frame(width: 38, height: 38)

                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let errorMessage = errorMessage {
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

                    // Save button
                    Button(action: saveTimeline) {
                        Text(isEditMode ? "保存修改" : "创建时间线")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isValid ? Color(hex: selectedColor) : Color.gray
                            )
                            .cornerRadius(14)
                    }
                    .disabled(!isValid)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
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

    // MARK: - Preview Card

    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColor))
                    .frame(width: 52, height: 52)

                if let image = customIconImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } else if let icon = selectedIcon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "时间线标题" : title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(title.isEmpty ? .secondary : .primary)

                Text(DateCalculator.formatShortDate(baseDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color(hex: selectedColor).opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: selectedColor).opacity(0.3), lineWidth: 1)
        )
    }

    private func loadCustomIcon(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        customIconImage = cropToSquare(image)
        selectedIcon = nil
        isNewImageSelected = true
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

        if let customImage = customIconImage {
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

// MARK: - Timeline Detail View
struct TimelineDetailView: View {
    let timeline: Timeline

    var body: some View {
        TimelineView(timeline: timeline)
    }
}

// MARK: - Color Extension
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
