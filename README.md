# Musai - AI Music Generator

## 项目概述

Musai是一款基于AI技术的音乐生成应用，允许用户通过上传图片和输入文本来创作独特的音乐作品。应用采用现代化的iOS开发技术栈，提供流畅的用户体验和高质量的音乐生成功能。

## 技术架构

### 客户端架构
- **架构模式**: Clean Architecture + MVVM
- **UI框架**: SwiftUI
- **数据持久化**: SwiftData
- **异步处理**: Swift Concurrency (async/await)
- **响应式编程**: Combine
- **音频处理**: AVFoundation
- **图片处理**: Core Image

### 后端服务
- **AI音乐生成**: Replicate API (minimax/music-1.5)
- **数据存储**: 本地SwiftData + 可选云端同步
- **图片处理**: 自定义图片处理服务

## 核心功能

### 1. AI Music页面
- 3:2比例的Banner图片展示
- 四步骤引导流程
- 清晰的视觉层次和交互设计

### 2. Create页面
- 图片上传功能（相机/相册）
- 歌曲标题和歌词输入
- 音乐风格选择（Pop、R&B、EDM、Rock、Jazz、Classical）
- 情感模式选择（Joyful、Melancholic、Motivational、Reflective、Chill）
- 播放速度控制（Slow、Medium、Fast）
- 乐器配置（Piano、Guitar、Synth、Orchestral、Percussion）
- 人声选择（Male、Female、No Limit）

### 3. 音乐生成结果页面
- 全屏沉浸式播放界面
- 图片虚化背景效果
- 实时歌词同步显示
- 完整的音频播放控制
- 社交分享功能

### 4. My Musics页面
- 历史作品网格展示
- 快速播放预览
- 作品详情查看
- 删除和分享功能
- 基础设置选项

## 项目结构

```
Musai/
├── Models/
│   └── MusicTrack.swift          # 数据模型
├── Views/
│   ├── MainTabView.swift         # 主标签栏
│   ├── AIMusicView.swift         # AI Music页面
│   ├── CreateView.swift          # 创建页面
│   ├── GenerationResultView.swift # 生成结果页面
│   └── MyMusicsView.swift        # 我的音乐页面
├── Services/
│   ├── MusicGenerationService.swift # 音乐生成服务
│   ├── AudioPlayerService.swift    # 音频播放服务
│   ├── ImageProcessingService.swift # 图片处理服务
│   └── LyricsSyncService.swift     # 歌词同步服务
├── Utilities/
│   └── Theme.swift               # 主题配置
└── MusaiApp.swift               # 应用入口
```

## 依赖管理

### 系统框架
- SwiftUI
- SwiftData
- AVFoundation
- Core Image
- PhotosUI
- Combine

### 第三方API
- Replicate API (minimax/music-1.5)

## 安全与隐私

### API密钥管理
- 使用Keychain安全存储API密钥
- 避免在代码中硬编码敏感信息
- 支持环境变量配置

### 数据保护
- 本地数据加密存储
- 图片压缩和隐私处理
- 用户数据最小化原则

### 合规性
- 遵循App Store审核指南
- 支持App Tracking Transparency
- 隐私政策声明

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
- 界面渲染测试

## 部署配置

### 开发环境
```bash
# 克隆项目
git clone [repository-url]
cd Musai

# 在Xcode中打开项目
open Musai.xcodeproj

# 配置API密钥
# 在MusicGenerationService.swift中设置YOUR_REPLICATE_API_KEY
```

### 生产环境
- App Store Connect配置
- 证书和配置文件设置
- 版本管理和发布流程

## API文档

### Replicate音乐生成API

**请求格式:**
```swift
POST https://api.replicate.com/v1/predictions
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "version": "minimax/music-1.5",
  "input": {
    "prompt": "音乐描述文本",
    "duration": 30,
    "model_version": "music-1.5"
  }
}
```

**响应格式:**
```json
{
  "id": "prediction_id",
  "status": "succeeded|processing|failed",
  "output": ["audio_url"]
}
```

## 上架检查清单

### 技术要求
- [ ] iOS 17.0+兼容性
- [ ] 64位架构支持
- [ ] 启动时间优化
- [ ] 内存使用优化

### 内容要求
- [ ] 应用图标设计
- [ ] 启动屏幕配置
- [ ] 应用描述和关键词
- [ ] 隐私政策链接

### 合规要求
- [ ] App Store审核指南遵循
- [ ] 隐私政策完整
- [ ] 权限使用说明
- [ ] 数据使用声明

### 功能测试
- [ ] 核心功能完整性
- [ ] 网络异常处理
- [ ] 设备兼容性测试
- [ ] 用户体验优化

## 常见问题

### Q: 如何配置Replicate API密钥？
A: 在`MusicGenerationService.swift`文件中将`YOUR_REPLICATE_API_KEY`替换为您的实际API密钥。

### Q: 应用支持哪些iOS版本？
A: 应用要求iOS 17.0及以上版本，以支持最新的SwiftUI和SwiftData功能。

### Q: 如何处理网络连接问题？
A: 应用内置了网络错误处理机制，会在网络异常时显示相应提示信息。

### Q: 生成的音乐文件存储在哪里？
A: 音乐文件默认存储在本地数据库中，支持云端同步扩展。

## 联系信息

- 开发者: Sun1
- 项目开始时间: 2025/11/3
- 技术支持: [support@example.com]

## 许可证

本项目采用MIT许可证，详情请参阅LICENSE文件。