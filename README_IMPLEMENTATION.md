# iOS 宝宝照片时间线应用 - 实现文档

## 项目概述

已成功实现基于 SwiftUI 的 iOS 宝宝成长时间线应用，使用 SwiftData 存储数据，通过 Photos.framework 访问系统相册，MapKit 展示照片位置。

## 已完成的功能

### ✅ 第一阶段：数据模型与工具类

1. **数据模型** (`Models/`)
   - `Baby.swift` - 宝宝信息模型，支持计算年龄
   - `TimelinePhoto.swift` - 时间线照片模型，关联到宝宝
   - `AgeInfo.swift` - 年龄信息结构体
   - `KeyMilestone.swift` - 关键里程碑枚举（出生、7天、满月、百天、周岁）

2. **工具类** (`Utils/`)
   - `DateCalculator.swift` - 日期计算和格式化工具
   - `Constants.swift` - UI 常量和应用颜色定义

### ✅ 第二阶段：服务层

3. **服务层** (`Services/`)
   - `PhotoService.swift` - 相册访问服务
     - 权限请求和检查
     - 图片获取和缓存
     - 支持批量获取
   - `EXIFService.swift` - EXIF 数据解析服务
     - 提取拍摄日期（DateTimeOriginal）
     - 提取相机和镜头信息
     - 提取 GPS 位置信息
     - 提取拍摄参数（ISO、光圈、快门、焦距）
   - `LocationService.swift` - 位置服务
     - 反向地理编码
     - 地址格式化
     - 结果缓存

### ✅ 第三阶段：欢迎页

4. **欢迎页** (`Views/`)
   - `OnboardingView.swift` - 创建宝宝档案界面
     - 头像选择器
     - 昵称输入
     - 出生日期选择
     - 初始照片选择
   - `ViewModels/OnboardingViewModel.swift` - 欢迎页业务逻辑

### ✅ 第四阶段：时间线

5. **时间线 UI** (`Views/` & `Views/Components/`)
   - `TimelineView.swift` - 时间线主视图
     - 照片分组展示
     - 横向滚动照片列表
     - 空状态处理
   - `ViewModels/TimelineViewModel.swift` - 时间线业务逻辑
     - 数据加载和排序
     - 照片添加功能
   - `Components/TimelineCell.swift` - 照片单元格
   - `Components/TimelineSectionView.swift` - 时间线分组视图
   - `Components/AgeBadge.swift` - 年龄标记组件

### ✅ 第五阶段：照片详情

6. **照片详情** (`Views/` & `Views/Components/`)
   - `PhotoDetailView.swift` - 照片详情页
     - 高清大图展示
     - 基本信息（拍摄时间、宝宝年龄）
     - 位置地图展示
     - EXIF 参数展示
     - 分享功能
   - `ViewModels/PhotoDetailViewModel.swift` - 详情页业务逻辑
   - `Components/EXIFInfoView.swift` - EXIF 信息展示组件
   - `Components/PhotoMapView.swift` - 地图组件

### ✅ 第六阶段：应用入口

7. **应用入口** (已清理示例代码)
   - `timelineApp.swift` - App 入口，配置 SwiftData schema
   - `ContentView.swift` - 路由入口，根据是否有宝宝档案显示不同界面

## 项目结构

```
timeline/
├── Models/                          # 数据模型
│   ├── AgeInfo.swift               # 年龄信息结构体
│   ├── Baby.swift                  # 宝宝模型
│   ├── KeyMilestone.swift          # 关键里程碑枚举
│   └── TimelinePhoto.swift         # 时间线照片模型
│
├── ViewModels/                      # 视图模型
│   ├── OnboardingViewModel.swift   # 欢迎页 ViewModel
│   ├── PhotoDetailViewModel.swift  # 照片详情 ViewModel
│   └── TimelineViewModel.swift     # 时间线 ViewModel
│
├── Views/                           # 视图
│   ├── Components/                 # UI 组件
│   │   ├── AgeBadge.swift          # 年龄标记
│   │   ├── EXIFInfoView.swift      # EXIF 信息展示
│   │   ├── PhotoMapView.swift      # 地图视图
│   │   ├── TimelineCell.swift      # 时间线单元格
│   │   └── TimelineSectionView.swift # 时间线分组
│   ├── OnboardingView.swift        # 欢迎页
│   ├── PhotoDetailView.swift       # 照片详情页
│   └── TimelineView.swift          # 时间线主视图
│
├── Services/                        # 服务层
│   ├── EXIFService.swift           # EXIF 解析服务
│   ├── LocationService.swift       # 位置服务
│   └── PhotoService.swift          # 相册访问服务
│
├── Utils/                           # 工具类
│   ├── Constants.swift             # 常量定义
│   └── DateCalculator.swift        # 日期计算工具
│
├── ContentView.swift                # 应用路由入口
└── timelineApp.swift               # App 入口
```

## 核心技术实现

### 1. 数据存储
- 使用 SwiftData 进行本地持久化
- Baby 和 TimelinePhoto 一对多关系
- 级联删除配置

### 2. 相册访问
- PHImageManager 封装
- 图片请求和内存缓存
- 异步加载支持

### 3. EXIF 解析
- CGImageSource 读取 EXIF 元数据
- 提取 DateTimeOriginal、相机信息、GPS 坐标
- 备用机制：EXIF 缺失时使用 PHAsset.creationDate

### 4. 地理位置展示
- CLGeocoder 反向地理编码
- MapKit 展示拍摄位置
- 缓存机制减少请求

### 5. 时间线计算
- 基于宝宝出生日期计算年龄
- 自动识别关键里程碑（0/7/30/100/365 天）
- 按日期和年龄分组展示

## 需要手动配置的权限

在 Xcode 中添加以下权限描述：

### 方法 1：通过 Xcode GUI
1. 选择项目 target
2. 进入 "Info" 标签
3. 添加以下键值对：

```xml
Key: Privacy - Photo Library Usage Description
Value: 需要访问相册来选择宝宝照片，创建成长时间线

Key: Privacy - Photo Library Add Usage Description
Value: 需要保存宝宝照片到时间线
```

### 方法 2：直接编辑 Info.plist（如果存在）

如果项目中存在 `Info.plist` 文件，添加：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择宝宝照片，创建成长时间线</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存宝宝照片到时间线</string>
```

## 待完善的功能

以下功能框架已实现，但需要额外处理：

### 1. PhotosPicker 完整集成
当前 `OnboardingView.swift` 和 `TimelineView.swift` 中的 PhotosPicker 需要完整实现：
- 将选中的图片保存到相册
- 获取 PHAsset.localIdentifier
- 关联到 TimelinePhoto

示例代码：
```swift
// 修改 OnboardingView.swift 和 TimelineView.swift 中的
// loadPhotos() 和 handlePhotoSelection() 方法

PHPhotoLibrary.shared().performChanges {
    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
    let localIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
    // 保存 localIdentifier
}
```

### 2. 头像保存
当前头像选择器需要完整实现保存逻辑。

### 3. 多宝宝支持
当前数据模型支持多个宝宝，但 UI 只处理第一个宝宝。未来可以扩展：
- 宝宝列表页面
- 切换不同宝宝的时间线

### 4. 数据迁移
考虑版本升级时的数据迁移策略。

## 测试建议

### 功能测试
1. 首次启动显示欢迎页
2. 创建宝宝档案（昵称、出生日期）
3. 选择照片添加到时间线
4. 检查时间线排序
5. 验证年龄计算
6. 查看照片详情
7. 确认 EXIF 数据正确显示
8. 测试地图位置展示
9. 测试分享功能

### 边界情况
- 无权限时的处理
- EXIF 缺失时的备用逻辑
- 空相册状态
- 无 GPS 信息的照片

## 设计亮点

1. **清晰的 MVVM 架构**
   - View 负责 UI 展示
   - ViewModel 处理业务逻辑
   - Service 层封装底层功能

2. **SwiftData 关系管理**
   - 使用 @Relationship 定义关联
   - 级联删除保证数据一致性

3. **异步加载**
   - 图片异步加载不阻塞 UI
   - TaskGroup 并发处理

4. **缓存机制**
   - PhotoService 内存缓存
   - LocationService 结果缓存

5. **组件化设计**
   - 可复用的 UI 组件
   - 清晰的职责分离

## 下一步

1. 在 Xcode 中打开项目
2. 配置相册权限（如上所述）
3. 完善照片选择器的保存逻辑
4. 运行测试
5. 根据需要调整 UI 细节

## 技术栈版本要求

- iOS 17.0+（SwiftData 要求）
- Xcode 15.0+
- Swift 5.9+

## 许可证

本项目代码仅供学习和参考使用。
