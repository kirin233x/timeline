//
//  PhotoDateEditView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI

struct PhotoDateEditView: View {
    let photo: TimelinePhoto
    let baby: Baby
    let onDateChanged: (Date) -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date
    @State private var displayOriginalDate: Date
    @Environment(\.dismiss) private var dismiss

    init(photo: TimelinePhoto, baby: Baby, onDateChanged: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.photo = photo
        self.baby = baby
        self.onDateChanged = onDateChanged
        self.onCancel = onCancel

        // 优先使用手动日期，然后 EXIF 日期，最后 asset 日期
        let initialDate = photo.manualDate ?? photo.exifDate ?? photo.assetDate
        _selectedDate = State(initialValue: initialDate)
        _displayOriginalDate = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationView {
            Form {
                // 原始日期信息
                Section(header: Text("原始信息")) {
                    if photo.exifDate != nil {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EXIF 日期")
                                    .font(.subheadline)
                                Text(DateCalculator.formatDate(photo.exifDate!))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                selectedDate = photo.exifDate!
                            }) {
                                Text("使用")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .cornerRadius(8)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("拍摄设备")
                                    .font(.subheadline)
                                if let camera = photo.cameraModel {
                                    Text(camera)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("资源日期")
                                .font(.subheadline)
                            Text(DateCalculator.formatDate(photo.assetDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            selectedDate = photo.assetDate
                        }) {
                            Text("使用")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .cornerRadius(8)
                        }
                    }
                }

                // 手动输入日期
                Section(header: Text("手动设置")) {
                    DatePicker(
                        "拍摄日期",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)

                    // 当前选择的日期对应的年龄
                    let ageInfo = baby.age(at: selectedDate)
                    HStack {
                        Text("宝宝年龄")
                        Spacer()
                        Text(ageInfo.displayText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                }

                // 快速选择
                Section(header: Text("快速调整")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach([-30, -7, -1, 1, 7, 30], id: \.self) { days in
                            QuickAdjustButton(days: days, action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
                                }
                            })
                        }
                    }
                }
            }
            .navigationTitle("修改照片日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onDateChanged(selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct QuickAdjustButton: View {
    let days: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: days < 0 ? "minus.circle.fill" : "plus.circle.fill")
                Text("\(abs(days))天")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(days < 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(days < 0 ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
            )
            .foregroundStyle(days < 0 ? .red : .green)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let baby = Baby(name: "测试宝宝", birthDate: Date().addingTimeInterval(-30*24*3600))
    let photo = TimelinePhoto(
        localIdentifier: "test",
        exifDate: Date().addingTimeInterval(-10*24*3600),
        assetDate: Date(),
        baby: baby
    )

    return PhotoDateEditView(
        photo: photo,
        baby: baby
    ) { newDate in
        print("新日期: \(newDate)")
    } onCancel: {
        print("取消")
    }
}
