# 照片选择和手动日期功能更新

## ✅ 修复的问题

### 1. 照片选择返回 0 张的问题

**原因：**
`PhotosPickerItem.itemIdentifier` 返回的不是 PHAsset 的 localIdentifier，导致无法获取照片。

**解决方案：**
现在会将选中的图片保存到相册，获取新创建的 PHAsset 的 localIdentifier。

### 2. 添加手动设置日期功能

当照片没有 EXIF 信息时，用户可以手动设置拍摄日期。

## 🔄 具体修改

### 1. OnboardingView.swift & TimelineView.swift

**新增函数：**
```swift
private func saveImageToPhotoLibrary(_ image: UIImage) async -> String? {
    return await withCheckedContinuation { continuation in
        var assetID: String?

        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetID = request.placeholderForCreatedAsset?.localIdentifier
        } completionHandler: { success, error in
            if success, let assetID = assetID {
                continuation.resume(returning: assetID)
            } else {
                print("保存图片失败: \(error?.localizedDescription ?? "未知错误")")
                continuation.resume(returning: nil)
            }
        }
    }
}
```

**功能：**
- 将从 PhotosPicker 选择的图片保存到相册
- 返回新创建的 PHAsset 的 localIdentifier
- 可以正确获取和显示照片

### 2. TimelinePhoto.swift - 数据模型更新

**新增字段：**
```swift
var manualDate: Date?  // 用户手动设置的日期
```

**修改后的逻辑：**
```swift
/// 获取实际拍摄时间（优先使用手动设置的日期）
var captureDate: Date {
    manualDate ?? exifDate ?? assetDate
}

/// 是否手动修改过日期
var hasManualDate: Bool {
    manualDate != nil
}
```

**日期优先级：**
1. 手动设置的日期（`manualDate`）
2. EXIF 日期（`exifDate`）
3. 资源日期（`assetDate`）

### 3. PhotoDateEditView.swift - 新增日期编辑视图

**功能：**
- 显示原始 EXIF 日期和资源日期
- 支持手动选择日期和时间
- 显示对应的宝宝年龄
- 快速调整按钮（±1天、±7天、±30天）
- 一键恢复到原始日期

**使用方式：**
```swift
PhotoDateEditView(
    photo: photo,
    baby: baby,
    onDateChanged: { newDate in
        photo.manualDate = newDate
        // 保存到数据库
    },
    onCancel: {
        // 关闭编辑界面
    }
)
```

### 4. PhotoDetailView.swift - 照片详情页更新

**新增功能：**
1. 右上角菜单
   - 分享
   - 修改日期

2. 日期来源标签
   - 🟢 绿色 "EXIF" - 来自 EXIF 元数据
   - 🟠 橙色 "手动设置" - 用户手动设置
   - ⚪ 灰色 "资源日期" - 使用 PHAsset 创建日期

3. 提示信息
   - 当照片没有 EXIF 且未手动设置时，显示橙色提示：
     "此照片没有 EXIF 信息，可点击右上角菜单修改日期"

## 🧪 测试流程

### 测试 1: 选择照片并保存

1. **运行应用**
   ```
   ⌘R
   ```

2. **在欢迎页选择照片**
   - 填写宝宝信息
   - 点击 "从相册选择照片"
   - 选择几张照片
   - **查看控制台输出：**
     ```
     开始处理选择的 3 个项目
     处理项目 1/3
       ✓ 成功加载图片数据
       ✓ 已保存到相册: xxx-xxx-xxx-xxx
     处理项目 2/3
       ✓ 成功加载图片数据
       ✓ 已保存到相册: xxx-xxx-xxx-xxx
     ...
     已选择 3 张照片
     ```

3. **点击 "创建档案"**
   - **控制台输出：**
     ```
     正在创建宝宝档案...
     选择的照片数量: 3
     开始处理 3 张照片...
     照片处理完成: 成功 3 张，失败 0 张
     ✅ 宝宝档案创建成功！
     ```

4. **验证照片显示**
   - 自动跳转到时间线
   - 可以看到按日期分组的照片
   - 照片显示在正确的日期位置

### 测试 2: 手动设置照片日期

1. **点击一张照片进入详情页**

2. **检查日期来源标签**
   - 有 EXIF：显示绿色 "EXIF" 标签
   - 无 EXIF：显示灰色 "资源日期" 标签
   - 手动设置：显示橙色 "手动设置" 标签

3. **修改日期**
   - 点击右上角 "⋯" 菜单
   - 选择 "修改日期"
   - 在编辑界面：
     - 查看原始日期信息
     - 选择新的日期和时间
     - 查看对应的宝宝年龄（实时更新）
     - 使用快速调整按钮微调
   - 点击 "保存"

4. **验证修改**
   - 返回详情页
   - 日期来源标签变为橙色 "手动设置"
   - 拍摄时间显示为新设置的日期
   - 宝宝年龄相应更新

5. **验证时间线更新**
   - 返回时间线
   - 照片应该移动到新的日期分组
   - 年龄标记相应更新

### 测试 3: EXIF 信息检查

**有 EXIF 的照片：**
- ✅ 显示绿色 "EXIF" 标签
- ✅ 使用 EXIF DateTimeOriginal
- ✅ 显示拍摄设备信息
- ✅ 可能包含位置信息

**无 EXIF 的照片：**
- ⚪ 显示灰色 "资源日期" 标签
- ✅ 使用 PHAsset.creationDate
- ⚠️ 不显示拍摄设备信息
- ⚠️ 通常没有位置信息
- 💡 显示橙色提示引导用户修改日期

## 📱 用户使用流程

### 场景 1: 从相册选择有 EXIF 的照片

1. 打开应用，创建宝宝档案
2. 从相册选择照片
3. 点击 "创建档案"
4. ✅ 照片自动按 EXIF 日期排序
5. ✅ 显示准确的宝宝年龄

### 场景 2: 处理没有 EXIF 的照片

**方法 1: 手动设置日期**
1. 从相册选择照片（如截图、导出的图片）
2. 创建档案
3. 照片会使用资源日期
4. 点击照片进入详情
5. 点击右上角 "⋯" → "修改日期"
6. 设置正确的拍摄日期
7. ✅ 时间线自动更新

**方法 2: 使用快速调整**
1. 在日期编辑界面
2. 使用快速调整按钮：
   - `-1 天`：提前 1 天
   - `+7 天`：延后 7 天
   - `-30 天`：提前 1 个月
3. 查看宝宝年龄实时更新
4. 保存后时间线自动排序

## 🔍 调试信息

### 控制台输出

**选择照片时：**
```
开始处理选择的 3 个项目
处理项目 1/3
  ✓ 成功加载图片数据
  ✓ 已保存到相册: xxx-xxx-xxx-xxx
处理项目 2/3
  ✓ 成功加载图片数据
  ✓ 已保存到相册: xxx-xxx-xxx-xxx
处理项目 3/3
  ✓ 成功加载图片数据
  ✓ 已保存到相册: xxx-xxx-xxx-xxx
已选择 3 张照片
照片 1: xxx-xxx-xxx-xxx
照片 2: xxx-xxx-xxx-xxx
照片 3: xxx-xxx-xxx-xxx
```

**创建档案时：**
```
正在创建宝宝档案...
宝宝昵称: 小明
出生日期: 2026-01-01
选择的照片数量: 3
开始处理 3 张照片...
处理照片 1/3: xxx-xxx-xxx-xxx
  ✓ 成功获取 PHAsset
  ✓ EXIF 日期: 2026-01-15
  ✓ 包含位置信息
  ✓ 拍摄设备: iPhone 15 Pro
处理照片 2/3: xxx-xxx-xxx-xxx
  ✓ 成功获取 PHAsset
处理照片 3/3: xxx-xxx-xxx-xxx
  ✓ 成功获取 PHAsset
照片处理完成: 成功 3 张，失败 0 张
✅ 宝宝档案创建成功！
```

## ⚠️ 注意事项

### 1. 保存到相册

现在从 PhotosPicker 选择的照片会保存到系统相册中：
- ✅ 每次选择都会创建新的 PHAsset
- ✅ localIdentifier 指向新创建的资源
- 💡 如果多次选择同一张照片，相册中会有多个副本

### 2. 数据迁移

如果之前已经创建了数据（但没有正确的 localIdentifier）：
- 需要删除旧数据
- 重新创建宝宝档案
- 重新选择照片

### 3. 权限要求

需要以下权限：
- ✅ 相册读取权限（选择照片）
- ✅ 相册写入权限（保存照片）

## 🎯 功能特性总结

### ✅ 已实现

1. **照片选择**
   - 从相册选择照片
   - 自动保存到相册获取 ID
   - 批量选择支持（最多 10 张）

2. **EXIF 解析**
   - 自动提取拍摄日期
   - 提取设备信息
   - 提取位置信息
   - 提取拍摄参数

3. **手动日期设置**
   - 无 EXIF 照片的日期编辑
   - 日期时间选择器
   - 快速调整按钮
   - 实时年龄预览

4. **智能排序**
   - 优先级：手动日期 > EXIF 日期 > 资源日期
   - 自动按时间排序
   - 自动计算年龄
   - 自动识别里程碑

5. **用户界面**
   - 日期来源标签（颜色区分）
   - 无 EXIF 提示
   - 编辑入口（右上角菜单）
   - 直观的编辑界面

### 💡 未来优化

1. **批量编辑日期**
   - 在时间线选择多张照片
   - 批量设置日期

2. **智能日期建议**
   - 根据附近照片的日期
   - 根据宝宝年龄推测

3. **日期冲突检测**
   - 提示相同时间的照片
   - 建议调整顺序

---

**更新完成！现在可以正常选择照片并手动设置日期了。** 🎉
