# 修复崩溃问题 - 快速指南

## 🚨 崩溃原因

应用崩溃是因为缺少相册权限配置。错误信息：
```
This app has crashed because it attempted to access privacy-sensitive data without a usage description.
The app's Info.plist must contain an NSPhotoLibraryUsageDescription key.
```

## ✅ 已创建 Info.plist

我已经在 `timeline/Info.plist` 中创建了必要的权限配置。

## 📝 在 Xcode 中配置权限

### 方法 1：在 Xcode GUI 中配置（推荐）

1. **打开项目**
   ```bash
   open timeline.xcodeproj
   ```

2. **选择 Target**
   - 点击项目导航器中的项目文件（蓝色图标）
   - 选择 "timeline" target

3. **进入 Info 标签**
   - 点击 "Info" 标签页

4. **添加权限描述**
   - 在 "Custom iOS Target Properties" 部分
   - 点击 "+" 按钮添加以下键值对：

   **Key 1:**
   - Key: `Privacy - Photo Library Usage Description`
   - Value: `需要访问相册来选择宝宝照片，创建成长时间线`

   **Key 2:**
   - Key: `Privacy - Photo Library Add Usage Description`
   - Value: `需要保存宝宝照片到时间线`

   **Key 3 (可选，用于地图):**
   - Key: `Privacy - Location When In Use Usage Description`
   - Value: `需要显示照片拍摄地点`

### 方法 2：使用已创建的 Info.plist 文件

我已经创建了 `timeline/Info.plist` 文件，需要在 Xcode 中：

1. **将 Info.plist 添加到项目**
   - 右键点击 `timeline` 文件夹
   - 选择 "Add Files to timeline..."
   - 选择 `Info.plist` 文件
   - 确保 "Copy items if needed" **不勾选**
   - 确保 "Add to targets" 勾选了 "timeline"
   - 点击 "Add"

2. **验证 Info.plist 配置**
   - 点击项目文件
   - 选择 "timeline" target
   - 进入 "Build Settings" 标签
   - 搜索 "Info.plist"
   - 找到 "Packaging" -> "Info.plist File"
   - 设置值为：`timeline/Info.plist`

3. **清理并重新运行**
   - 按 ⌘Shift+K 清理构建
   - 按 ⌘R 运行

## 🎯 验证配置

配置完成后，Info.plist 应该包含：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择宝宝照片，创建成长时间线</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存宝宝照片到时间线</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>需要显示照片拍摄地点</string>
```

## 🔄 重新运行

1. **清理构建缓存**
   ```
   Product -> Clean Build Folder (⌘Shift+K)
   ```

2. **删除 DerivedData**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/timeline-*
   ```

3. **重新运行**
   ```
   按 ⌘R
   ```

## ✅ 成功标志

重新运行后：
- ✅ 应用正常启动
- ✅ 首次启动显示欢迎页
- ✅ 请求相册权限时弹出系统对话框
- ✅ 授权后可以正常使用

## ❓ 如果仍然崩溃

检查以下内容：

1. **Info.plist 是否添加到 Target**
   - 点击 Info.plist 文件
   - 在右侧 File Inspector 中
   - 确保 "Target Membership" 勾选了 "timeline"

2. **Info.plist 路径是否正确**
   - Build Settings -> Info.plist File
   - 应该是：`timeline/Info.plist`

3. **Clean Build Folder**
   - Product -> Clean Build Folder (⌘Shift+K)

4. **重启 Xcode**
   - 完全退出 Xcode
   - 重新打开项目

## 📱 权限对话框示例

配置正确后，首次访问相册时会看到系统弹窗：

```
"timeline" 想访问您的照片

需要访问相册来选择宝宝照片，创建成长时间线

[ 不允许 ]  [ 允许访问所有照片 ]
```

## 🔍 调试技巧

如果需要检查权限是否正确配置，可以在代码中添加调试输出：

```swift
// 在 TimelineView 或 OnboardingView 中
import Photos

func checkPermission() {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    print("Photo authorization status: \(status.rawValue)")
}
```

---

**问题解决后，应用应该可以正常运行！** 🎉
