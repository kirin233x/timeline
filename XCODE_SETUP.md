# Xcode 项目配置指南

## 添加新文件到 Xcode 项目

由于我们在命令行创建了新文件，需要将它们添加到 Xcode 项目中。有两种方法：

### 方法 1：自动重新生成（推荐）

在终端运行以下命令，让 Xcode 自动发现新文件：

```bash
# 清理构建缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/timeline-*

# 在 Xcode 中重新打开项目
open timeline.xcodeproj
```

然后在 Xcode 中：
1. 右键点击 `timeline` 文件夹
2. 选择 "Add Files to timeline..."
3. 找到并添加所有新创建的文件夹

### 方法 2：手动添加文件组

在 Xcode 中：

1. **创建以下 Groups（文件夹组）：**
   - Models
   - ViewModels
   - Views
   - Views/Components
   - Services
   - Utils

2. **添加文件到对应 Group：**

   **Models 组：**
   - AgeInfo.swift
   - Baby.swift
   - KeyMilestone.swift
   - TimelinePhoto.swift

   **ViewModels 组：**
   - OnboardingViewModel.swift
   - PhotoDetailViewModel.swift
   - TimelineViewModel.swift

   **Views 组：**
   - OnboardingView.swift
   - PhotoDetailView.swift
   - TimelineView.swift

   **Views/Components 组：**
   - AgeBadge.swift
   - EXIFInfoView.swift
   - PhotoMapView.swift
   - TimelineCell.swift
   - TimelineSectionView.swift

   **Services 组：**
   - EXIFService.swift
   - LocationService.swift
   - PhotoService.swift

   **Utils 组：**
   - Constants.swift
   - DateCalculator.swift

3. **删除旧文件：**
   - 删除 `Item.swift`（如果仍在项目中）

## 配置权限

### 1. 选择 Target
点击项目导航器中的项目文件，选择 "timeline" target

### 2. 添加权限描述

在 "Info" 标签页中，添加以下自定义键值：

**Key:** `Privacy - Photo Library Usage Description`
**Value:** `需要访问相册来选择宝宝照片，创建成长时间线`

**Key:** `Privacy - Photo Library Add Usage Description`
**Value:** `需要保存宝宝照片到时间线`

### 3. 或者直接编辑 Info.plist

如果项目中有 Info.plist 文件：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择宝宝照片，创建成长时间线</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存宝宝照片到时间线</string>
```

## 依赖框架检查

确保以下框架已链接（Xcode 通常会自动处理）：
- SwiftUI
- SwiftData
- Photos
- MapKit
- CoreLocation
- ImageIO

如果未自动添加：
1. 选择项目 target
2. 进入 "Build Phases" 标签
3. 展开 "Link Binary With Libraries"
4. 点击 "+" 添加上述框架

## 部署目标设置

确保最低部署版本设置为 **iOS 17.0** 或更高（SwiftData 要求）：
1. 选择项目 target
2. "General" 标签
3. "Minimum Deployments" -> "iOS" 设置为 17.0

## 构建和运行

1. 选择模拟器或真机设备
2. 点击 ▶️ 运行按钮或按 ⌘R
3. 首次启动会显示欢迎页

## 常见问题

### 问题 1：找不到 SwiftData
**解决：** 确保部署目标是 iOS 17.0+

### 问题 2：编译错误 "Cannot find 'XXX' in scope"
**解决：** 检查文件是否正确添加到项目，并确保 Target Membership 勾选

### 问题 3：PhotosPicker 无反应
**解决：** 确保在真机或支持相册的模拟器上运行

### 问题 4：地图不显示
**解决：** 检查是否在 capabilities 中启用了 Maps 权限（iOS 17+ 通常不需要）

## 项目验证清单

- [ ] 所有 22 个 Swift 文件已添加到项目
- [ ] 删除了 Item.swift
- [ ] 配置了相册权限
- [ ] 部署目标是 iOS 17.0+
- [ ] 项目可以成功编译
- [ ] 应用可以启动并显示欢迎页

## 文件清单

**核心文件（22 个）：**

```
Models/
├── AgeInfo.swift
├── Baby.swift
├── KeyMilestone.swift
└── TimelinePhoto.swift

ViewModels/
├── OnboardingViewModel.swift
├── PhotoDetailViewModel.swift
└── TimelineViewModel.swift

Views/
├── Components/
│   ├── AgeBadge.swift
│   ├── EXIFInfoView.swift
│   ├── PhotoMapView.swift
│   ├── TimelineCell.swift
│   └── TimelineSectionView.swift
├── OnboardingView.swift
├── PhotoDetailView.swift
└── TimelineView.swift

Services/
├── EXIFService.swift
├── LocationService.swift
└── PhotoService.swift

Utils/
├── Constants.swift
└── DateCalculator.swift

Root/
├── ContentView.swift
└── timelineApp.swift
```

## 下一步

完成 Xcode 配置后：
1. 编译运行
2. 测试欢迎页流程
3. 完善照片选择器的保存逻辑
4. 添加单元测试（可选）
5. 优化 UI 细节
