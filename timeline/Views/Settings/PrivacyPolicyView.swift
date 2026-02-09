//
//  PrivacyPolicyView.swift
//  timeline
//
//  Created by Claude on 2026/2/9.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("隐私政策")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("最后更新：2026年2月9日")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                // Introduction
                PolicySection(
                    icon: "lock.shield.fill",
                    iconColor: .blue,
                    title: "概述",
                    content: """
                    「时间线」是一款完全本地化的照片时间线记录应用。我们高度重视您的隐私，\
                    并致力于保护您的个人信息。本隐私政策说明了我们如何收集、使用和保护您的数据。
                    """
                )

                PolicySection(
                    icon: "iphone",
                    iconColor: .green,
                    title: "数据存储",
                    content: """
                    所有数据完全存储在您的设备本地：

                    • 照片文件存储在应用沙盒内
                    • 时间线数据使用 SwiftData 本地数据库
                    • 缩略图缓存存储在设备缓存目录

                    我们不会将任何数据上传到服务器或云端。
                    """
                )

                PolicySection(
                    icon: "photo.on.rectangle",
                    iconColor: .orange,
                    title: "照片访问",
                    content: """
                    应用需要访问您的照片库权限，用于：

                    • 导入您选择的照片到时间线
                    • 读取照片的 EXIF 元数据（拍摄日期、相机信息等）
                    • 读取照片的位置信息（如有）

                    我们只会访问您明确选择导入的照片，不会访问其他照片。
                    """
                )

                PolicySection(
                    icon: "location.fill",
                    iconColor: .red,
                    title: "位置信息",
                    content: """
                    应用会读取照片中包含的地理位置信息，用于：

                    • 在照片详情页显示拍摄地点
                    • 反向地理编码获取地点名称

                    应用不会追踪您的实时位置，仅使用照片中已有的位置数据。
                    """
                )

                PolicySection(
                    icon: "network.slash",
                    iconColor: .purple,
                    title: "网络使用",
                    content: """
                    应用主要在离线状态下工作。网络请求仅用于：

                    • 反向地理编码（将坐标转换为地名）

                    除此之外，应用不会发送任何数据到互联网。
                    """
                )

                PolicySection(
                    icon: "hand.raised.fill",
                    iconColor: .pink,
                    title: "第三方服务",
                    content: """
                    应用不使用任何第三方分析、广告或追踪服务。

                    您的数据完全属于您自己。
                    """
                )

                PolicySection(
                    icon: "trash.fill",
                    iconColor: .gray,
                    title: "数据删除",
                    content: """
                    您可以随时在设置中清除所有数据，或通过删除应用来移除所有相关数据。

                    删除应用后，所有存储在应用沙盒内的照片和数据将被永久移除。
                    """
                )

                PolicySection(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "联系我们",
                    content: """
                    如果您对我们的隐私政策有任何疑问或建议，请联系我们：

                    support@timeline-app.com
                    """
                )

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Policy Section Component

struct PolicySection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 32)

                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
