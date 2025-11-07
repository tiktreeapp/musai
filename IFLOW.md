# Musai - AI音乐生成应用上下文

## 项目概述

Musai是一款基于AI技术的iOS音乐生成应用，允许用户通过输入文本描述和上传图片来创作独特的音乐作品。应用采用现代化的SwiftUI开发技术栈，提供流畅的用户体验和高质量的音乐生成功能。

### 核心技术栈
- **架构模式**: Clean Architecture + MVVM
- **UI框架**: SwiftUI
- **数据持久化**: SwiftData
- **异步处理**: Swift Concurrency (async/await)
- **音频处理**: AVFoundation
- **图片处理**: Core Image
- **网络请求**: URLSession
- **响应式编程**: Combine

### 主要功能模块
1. **AI音乐生成**: 通过Replicate API (minimax/music-1.5)生成音乐
2. **音乐播放**: 基于AVPlayer的音频播放服务
3. **本地存储**: 使用SwiftData和文件系统管理音乐数据
4. **云端同步**: 集成Cloudinary进行音乐文件云存储
5. **歌词同步**: 实时歌词显示功能

## 项目结构

```
Musai/
├── Models/
│   └── MusicTrack.swift          # 音乐数据模型和枚举类型
├── Views/
│   ├── MainTabView.swift         # 主标签栏视图
│   ├── AIMusicView.swift         # AI音乐首页
│   ├── CreateView.swift          # 音乐创建页面
│   ├── GenerationResultView.swift # 音乐生成结果页面
│   └── MyMusicsView.swift        # 我的音乐列表页面
├── Services/
│   ├── MusicGenerationService.swift # 音乐生成服务（核心）
│   ├── AudioPlayerService.swift    # 音频播放服务
│   ├── MusicStorageService.swift   # 音乐存储服务
│   ├── LegacyMusicCacheService.swift # 旧音乐缓存服务
│   ├── ImageProcessingService.swift # 图片处理服务
│   └── LyricsSyncService.swift     # 歌词同步服务
├── Utilities/
│   └── Theme.swift               # 主题配置
└── MusaiApp.swift               # 应用入口
```

## 核心服务详解

### MusicGenerationService (音乐生成服务)
负责与Replicate API交互生成音乐，是应用的核心服务。

**主要功能**:
- 调用Replicate API生成音乐
- 轮询检查生成状态
- 上传图片到Cloudinary
- 管理生成进度和错误处理

**API密钥**:
- Replicate API Key: 从环境变量 `REPLICATE_API_KEY` 读取
- Cloudinary配置已内置，从环境变量读取敏感信息

### AudioPlayerService (音频播放服务)
基于AVPlayer实现的音频播放服务，支持播放控制和进度监听。

**主要功能**:
- 加载和播放音频文件
- 播放/暂停/停止控制
- 进度跳转和快进快退
- 播放时间监听

### MusicStorageService (音乐存储服务)
管理音乐文件的本地缓存和云端存储。

**主要功能**:
- 音乐文件本地缓存
- 上传音乐到Cloudinary
- 管理存储空间和缓存清理
- 提供播放URL获取逻辑

## 数据模型

### MusicTrack (音乐轨道模型)
使用SwiftData定义的音乐数据模型，包含以下属性:
- id: UUID (唯一标识)
- title: String (标题)
- lyrics: String (歌词)
- 音乐属性枚举 (style, mode, speed, instrumentation, vocal)
- imageData: Data? (关联图片数据)
- 链接和状态字段 (audioURL, localFilePath, cloudinaryURL等)
- 时间和统计字段 (createdAt, duration, playCount等)

### 音乐属性枚举
- **MusicStyle**: 音乐风格 (Pop, R&B, EDM, Rock, Jazz, Classical)
- **MusicMode**: 情感模式 (Joyful, Melancholic, Motivational, Reflective, Chill)
- **MusicSpeed**: 播放速度 (Slow, Medium, Fast)
- **MusicInstrumentation**: 乐器配置 (Piano, Guitar, Synth, Orchestral, Percussion)
- **MusicVocal**: 人声选择 (Male, Female, No Limit)

## 视图结构

### MainTabView (主标签栏)
应用的主入口，包含三个标签页:
1. **AI Music**: 应用介绍和引导页面
2. **Create**: 音乐创建页面
3. **My Songs**: 用户音乐作品列表

### CreateView (创建页面)
音乐创作的核心页面，提供完整的参数配置:
- 图片上传 (相机/相册)
- 歌曲标题和歌词输入
- 音乐风格、情感模式、播放速度选择
- 乐器配置和人声选择
- 音乐生成按钮

### GenerationResultView (生成结果页面)
展示音乐生成结果的沉浸式页面:
- 全屏图片背景
- 实时歌词同步显示
- 音频播放控制
- 社交分享功能

### MyMusicsView (我的音乐页面)
用户音乐作品管理页面:
- 网格布局展示历史作品
- 快速播放预览
- 作品详情查看
- 删除和分享功能

## 构建和运行

### 开发环境要求
- Xcode 15.0+
- iOS 17.0+ 模拟器或设备
- Swift 5.9+

### 构建步骤
1. 克隆项目到本地
2. 在Xcode中打开 `Musai.xcodeproj`
3. 选择目标设备或模拟器
4. 点击运行按钮或按 `Cmd+R`

### 配置说明
- API密钥已内置在 `MusicGenerationService.swift` 中
- 无需额外环境变量配置即可运行

## 测试策略

### 单元测试
- 业务逻辑测试
- 数据模型测试
- 服务层测试

### 集成测试
- API集成测试
- 数据持久化测试
- 音频播放测试

### UI测试
- XCUITest自动化测试
- 用户交互流程测试

## 性能优化

### 内存管理
- 图片压缩和缓存
- 音频流式播放
- 及时释放资源

### 网络优化
- 异步网络请求
- 请求超时处理
- 错误重试机制

### UI性能
- 懒加载列表
- 动画性能优化
- 响应式布局

## 安全与隐私

### API密钥管理
- 使用代码内置API密钥
- 支持Keychain安全存储扩展

### 数据保护
- 本地数据加密存储
- 图片压缩和隐私处理
- 用户数据最小化原则

## 部署配置

### App Store准备
- 确保iOS 17.0+兼容性
- 优化启动时间和内存使用
- 完善应用图标和启动屏幕
- 准备应用描述和隐私政策

## 常见问题

### Q: 如何配置Replicate API密钥？
A: API密钥已内置在`MusicGenerationService.swift`中，无需额外配置。

### Q: 应用支持哪些iOS版本？
A: 应用要求iOS 17.0及以上版本，以支持最新的SwiftUI和SwiftData功能。

### Q: 如何处理网络连接问题？
A: 应用内置了网络错误处理机制，会在网络异常时显示相应提示信息。

### Q: 生成的音乐文件存储在哪里？
A: 音乐文件默认存储在本地缓存目录中，并支持云端同步扩展。