//
//  EXIFInfoView.swift
//  timeline
//
//  Created by Kirin on 2026/2/1.
//

import SwiftUI

struct EXIFInfoView: View {
    let exifData: EXIFData?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let exif = exifData {
                // 拍摄设备
                if let camera = exif.cameraModel {
                    InfoRow(icon: "camera.fill", title: "拍摄设备", value: camera)
                }

                // 镜头
                if let lens = exif.lensModel {
                    InfoRow(icon: "camera.aperture", title: "镜头", value: lens)
                }

                // 如果有设备信息，添加分隔符
                if exif.cameraModel != nil || exif.lensModel != nil {
                    if exif.iso != nil || exif.aperture != nil || exif.shutterSpeed != nil || exif.focalLength != nil {
                        Divider()
                    }
                }

                // ISO
                if let iso = exif.iso {
                    InfoRow(icon: "circle.circle", title: "ISO", value: String(format: "%.0f", iso))
                }

                // 光圈
                if let aperture = exif.aperture {
                    InfoRow(icon: "aperture", title: "光圈", value: String(format: "f/%.1f", aperture))
                }

                // 快门速度
                if let shutter = exif.shutterSpeed {
                    InfoRow(icon: "timer", title: "快门", value: formatShutterSpeed(shutter))
                }

                // 焦距
                if let focal = exif.focalLength {
                    InfoRow(icon: "scale.3d", title: "焦距", value: String(format: "%.0fmm", focal))
                }

                // 只有所有字段都为空时才显示提示
                if exif.cameraModel == nil && exif.lensModel == nil &&
                   exif.iso == nil && exif.aperture == nil &&
                   exif.shutterSpeed == nil && exif.focalLength == nil {
                    Text("暂无 EXIF 信息")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("暂无 EXIF 信息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(Constants.cornerRadius)
    }

    private func formatShutterSpeed(_ seconds: Double) -> String {
        if seconds < 1 {
            let denominator = Int(1.0 / seconds)
            return "1/\(denominator)s"
        } else {
            return String(format: "%.1fs", seconds)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }

            Spacer()
        }
    }
}

#Preview {
    let exifData = EXIFData(
        dateTimeOriginal: Date(),
        cameraModel: "iPhone 15 Pro",
        lensModel: "Main Camera",
        iso: 100,
        aperture: 1.8,
        shutterSpeed: 0.003125,
        focalLength: 24,
        location: nil
    )

    return EXIFInfoView(exifData: exifData)
        .padding()
}
