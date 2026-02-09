//
//  AboutView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI

struct AboutView: View {
    @State private var showingCredits = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon & Name
                VStack(spacing: 16) {
                    ZStack {
                        LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)
                        .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)

                        Image(systemName: "timeline.selection")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 4) {
                        Text("时间线")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("记录每一个珍贵时刻")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("版本 \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 20)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("功能特色")
                        .font(.headline)
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        FeatureRow(
                            icon: "photo.stack.fill",
                            iconColor: .blue,
                            title: "照片时间线",
                            description: "按时间自动整理照片，清晰展示成长轨迹"
                        )
                        Divider().padding(.leading, 60)

                        FeatureRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "里程碑标记",
                            description: "自动识别并突出显示重要时刻"
                        )
                        Divider().padding(.leading, 60)

                        FeatureRow(
                            icon: "lock.fill",
                            iconColor: .green,
                            title: "隐私优先",
                            description: "所有数据本地存储，不上传云端"
                        )
                        Divider().padding(.leading, 60)

                        FeatureRow(
                            icon: "camera.fill",
                            iconColor: .orange,
                            title: "EXIF 信息",
                            description: "自动读取相机参数和位置信息"
                        )
                        Divider().padding(.leading, 60)

                        FeatureRow(
                            icon: "paintbrush.fill",
                            iconColor: .purple,
                            title: "自定义主题",
                            description: "为每个时间线选择专属颜色和图标"
                        )
                    }
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }

                // Credits
                VStack(spacing: 12) {
                    Button {
                        showingCredits = true
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                            Text("致谢")
                                .foregroundStyle(.primary)
                        }
                        .font(.subheadline)
                    }

                    Text("用 SwiftUI 和 ❤️ 构建")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("© 2026 Timeline App")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .padding(.vertical, 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCredits) {
            CreditsView()
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Credits View

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("感谢以下开源项目和资源")
                        .font(.headline)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 16) {
                        CreditItem(
                            name: "SwiftUI",
                            description: "Apple 的声明式 UI 框架"
                        )

                        CreditItem(
                            name: "SwiftData",
                            description: "Apple 的数据持久化框架"
                        )

                        CreditItem(
                            name: "SF Symbols",
                            description: "Apple 的系统图标库"
                        )

                        CreditItem(
                            name: "Core Location",
                            description: "位置服务和地理编码"
                        )

                        CreditItem(
                            name: "ImageIO",
                            description: "高效的图像处理框架"
                        )
                    }

                    Divider()

                    Text("特别感谢")
                        .font(.headline)

                    Text("感谢所有使用「时间线」的用户，你们的支持是我们前进的动力。")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("致谢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreditItem: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
