# 部署指南

## 项目设置步骤

### 1. 在Xcode中添加文件
由于Xcode使用了文件系统同步组，需要手动将新创建的文件添加到项目中：

1. 在Xcode中打开项目
2. 右键点击Musai文件夹
3. 选择"Add Files to Musai"
4. 添加以下文件：
   - `Models/MusicTrack.swift`
   - `Views/MainTabView.swift`
   - `Views/AIMusicView.swift`
   - `Views/CreateView.swift`
   - `Views/GenerationResultView.swift`
   - `Views/MyMusicsView.swift`
   - `Services/MusicGenerationService.swift`
   - `Services/AudioPlayerService.swift`
   - `Services/ImageProcessingService.swift`
   - `Services/LyricsSyncService.swift`
   - `Utilities/Theme.swift`

### 2. 配置API密钥
在`Services/MusicGenerationService.swift`中：
```swift
private let apiKey = "YOUR_REPLICATE_API_KEY"
```
替换为您的实际Replicate API密钥。

### 3. 添加权限
在`Info.plist`中添加：
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to upload images for music generation.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to take photos for music generation.</string>
```

### 4. 配置应用图标和启动屏幕
- 设置应用图标
- 配置启动屏幕
- 添加必要的App Store信息

### 5. 运行和测试
1. 选择模拟器或真机
2. 构建并运行应用
3. 测试核心功能

## 故障排除

### 编译错误
如果遇到编译错误，请检查：
1. 所有文件是否已正确添加到项目
2. 目标iOS版本设置（最低iOS 17.0）
3. Swift编译器版本兼容性

### 运行时错误
如果遇到运行时错误，请检查：
1. API密钥配置
2. 网络权限设置
3. 数据库权限

### 功能测试
建议按以下顺序测试功能：
1. 基础UI导航
2. 图片上传功能
3. 音乐参数配置
4. API集成
5. 音频播放
6. 数据持久化

## 性能优化建议

1. **图片处理**：使用适当的压缩比例
2. **网络请求**：实现适当的缓存策略
3. **内存管理**：及时释放音频和图片资源
4. **UI性能**：使用懒加载和虚拟化列表

## 安全检查清单

1. [ ] API密钥安全存储
2. [ ] 用户数据加密
3. [ ] 网络请求安全
4. [ ] 隐私政策完整
5. [ ] 权限使用说明

## App Store上架准备

1. **应用信息**：完成应用描述、关键词等
2. **截图准备**：应用界面截图
3. **隐私政策**：准备隐私政策链接
4. **审核信息**：准备审核备注
5. **测试账号**：如需要，提供测试账号

## 技术支持

如有技术问题，请检查：
1. iOS版本兼容性
2. Xcode版本兼容性
3. 依赖框架版本
4. 设备特定问题