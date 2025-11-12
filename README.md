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
- **订阅管理**: StoreKit 2

### 后端服务架构
- **AI音乐生成**: 自建后端 + Replicate API (minimax/music-1.5)
  - 后端服务地址: https://musai-backend.onrender.com
  - Node.js SDK集成，支持REST API和SDK调用
  - 图片上传至Cloudinary云存储
- **云存储服务**: Cloudinary
  - 云端名称: dygx9d3gi
  - 上传预设: musai_unsigned
- **数据存储**: 本地SwiftData + Cloudinary云端同步
- **歌词生成**: 阶跃星辰API (StepfunLyricsService)

### 核心服务层
1. **MusicGenerationService**: 音乐生成核心服务
   - 支持AI Lyrics和Own Lyrics两种模式
   - 异步轮询机制检查生成状态
   - 自动处理相对URL转换为绝对URL
   - 错误重试和超时处理

2. **AudioPlayerService**: 音频播放服务
   - 基于AVPlayer实现
   - 支持播放/暂停/停止控制
   - 实时进度监听和时间显示
   - 自动加载和缓存音频

3. **MusicStorageService**: 音乐存储管理
   - 本地文件缓存管理
   - Cloudinary云端上传
   - 存储空间监控和清理
   - 播放URL智能选择（本地优先，云端备选）

4. **SubscriptionManager**: 订阅管理服务
   - StoreKit 2集成
   - 支持周会员(300钻石)和月会员(1200钻石)
   - 本地订阅状态缓存
   - 交易验证和恢复购买功能

## 核心功能

### 1. AI Music页面
- **Banner展示**: 3:2比例动态Banner图片
- **AI音乐列表**: 展示云端推荐音乐或用户创作
- **四步骤引导**: 
  1. 上传灵感图片
  2. 输入音乐内容（标题+歌词）
  3. 选择音乐参数（风格、情感等）
  4. 一键生成AI音乐
- **快速入口**: Start按钮直接跳转创建页面

### 2. Create页面（核心创作功能）
- **图片上传**:
  - 支持相机拍摄和相册选择
  - 自动压缩至100KB以内
  - 保持宽高比的智能裁剪
  - PHPhotoLibrary权限管理

- **歌词系统**:
  - AI Lyrics模式：调用阶跃星辰API自动生成歌词
  - Own Lyrics模式：支持粘贴和手动输入
  - 支持标准歌词标签[intro][Verse][Chorus][Outro]

- **音乐参数配置**:
  - 风格(Style): Pop, R&B, EDM, Rock, Jazz, Classical
  - 情感(Mode): Joyful, Melancholic, Motivational, Reflective, Chill
  - 速度(Speed): Slow, Medium, Fast
  - 乐器(Instrumentation): Piano, Guitar, Synth, Orchestral, Percussion
  - 人声(Vocal): Male, Female, No Limit

- **钻石消费系统**:
  - 每次创作消耗10钻石
  - 实时余额显示
  - 余额不足时自动引导至订阅页面

### 3. 音乐生成流程
- **后端API集成**:
  - 图片上传至Cloudinary获取URL
  - Node.js SDK格式请求后端
  - 异步轮询获取生成结果
  - 自动处理503服务不可用错误

- **优化策略**:
  - 获取URL后立即跳转播放页面
  - 后台异步缓存音乐文件
  - 最大轮询60次，避免无限等待
  - 智能URL转换（相对路径转绝对路径）

### 4. GenerationResultView（播放页面）
- **沉浸式体验**:
  - 全屏图片背景with高斯模糊
  - 实时歌词同步滚动
  - 手势控制播放进度

- **播放控制**:
  - 播放/暂停/进度拖动
  - 快进快退（15秒）
  - 实时时间显示
  - 音频缓存和流式播放

- **社交分享**:
  - 支持分享至社交媒体
  - 自动生成分享文案
  - 包含应用图标和链接

### 5. My Musics页面
- **作品管理**:
  - 网格布局展示历史作品
  - 封面图、标题、风格信息
  - 快速播放预览功能
  - 滑动删除操作

- **云端同步**:
  - 自动上传至Cloudinary
  - 上传进度显示
  - 本地/云端智能切换

- **设置功能**:
  - 订阅管理入口
  - 应用分享功能
  - 评价和反馈
  - 版本信息显示

### 6. 订阅系统
- **会员体系**:
  - 周会员：300钻石/周，$4.99
  - 月会员：1200钻石/月，$12.99（40%优惠）
  - 新用户赠送5钻石

- **StoreKit 2集成**:
  - 原生iOS购买流程
  - 交易验证和状态检查
  - 恢复购买功能
  - 兑换码支持

- **钻石系统**:
  - 本地持久化存储
  - 实时余额同步
  - 消费记录追踪

## 项目结构

```
Musai/
├── Models/
│   ├── MusicTrack.swift          # 音乐数据模型和枚举定义
│   └── LyricLine.swift           # 歌词行数据模型
├── Views/
│   ├── MainTabView.swift         # 主标签栏视图
│   ├── AIMusicView.swift         # AI音乐首页
│   ├── CreateView.swift          # 音乐创建页面（核心功能）
│   ├── GenerationResultView.swift # 音乐生成结果页面
│   ├── MyMusicsView.swift        # 我的音乐列表页面
│   ├── SubscriptionView.swift    # 订阅购买页面
│   ├── WelcomeView.swift         # 欢迎引导页面
│   ├── VideoBackgroundView.swift # 视频背景组件
│   ├── StorageManagementView.swift # 存储管理视图
│   └── CreateViewTest.swift      # 创建页面测试
├── Services/
│   ├── MusicGenerationService.swift # 音乐生成服务（核心）
│   ├── AudioPlayerService.swift    # 音频播放服务
│   ├── MusicStorageService.swift   # 音乐存储服务
│   ├── LegacyMusicCacheService.swift # 旧音乐缓存服务
│   ├── ImageProcessingService.swift # 图片处理服务
│   ├── LyricsSyncService.swift     # 歌词同步服务
│   ├── StepfunLyricsService.swift  # 阶跃星辰歌词生成服务
│   ├── CloudinaryService.swift     # Cloudinary云存储服务
│   └── SubscriptionManager.swift   # 订阅管理服务
├── Utilities/
│   ├── Theme.swift               # 主题配置
│   ├── NetworkConfig.swift       # 网络配置
│   ├── NetworkDebugger.swift     # 网络调试工具
│   └── VideoLooper.swift         # 视频循环播放工具
├── Videos/                       # 应用内视频资源
│   ├── intro1.mp4
│   ├── intro2.mp4
│   └── intro3.mp4
├── Assets.xcassets/              # 图片资源
│   ├── AppIcon.appiconset/       # 应用图标
│   ├── Banner-01.imageset/       # Banner图片
│   ├── ProBG.imageset/           # 会员背景图
│   └── AccentColor.colorset/     # 主题色
├── MusaiApp.swift               # 应用入口
└── ContentView.swift            # 默认内容视图
```

## 依赖管理

### 系统框架
- **SwiftUI**: 现代化UI框架
- **SwiftData**: 本地数据持久化
- **AVFoundation**: 音频播放和处理
- **Core Image**: 图片处理和滤镜
- **PhotosUI**: 相册访问和图片选择
- **Combine**: 响应式编程
- **StoreKit 2**: 应用内购买和订阅
- **Photos**: 相册权限管理

### 第三方服务
- **Replicate API**: AI音乐生成 (minimax/music-1.5)
  - 通过自建后端代理调用
  - 支持异步生成和状态轮询
- **Cloudinary**: 云存储服务
  - 图片和音频文件存储
  - CDN加速分发
- **阶跃星辰API**: AI歌词生成
  - 支持根据标题生成完整歌词

### 开发工具
- **Xcode 15.0+**: 开发环境
- **iOS 17.0+**: 最低支持版本
- **Swift 5.9+**: 编程语言版本

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

### 后端音乐生成API

**基础URL**: `https://musai-backend.onrender.com`

**1. 生成音乐**
```http
POST /api/generate
Content-Type: application/json

{
  "lyrics": "歌词内容",
  "prompt": "Jazz, Smooth Jazz, Romantic, Dreamy",
  "bitrate": 256000,
  "sample_rate": 44100,
  "audio_format": "mp3",
  "image": "base64编码的图片数据"
}
```

**响应**:
```json
{
  "predictionId": "prediction_id",
  "status": "processing"
}
```

**2. 查询生成状态**
```http
GET /api/status/{predictionId}
```

**响应**:
```json
{
  "status": "succeeded|processing|failed",
  "musicURL": "https://domain.com/music.mp3",
  "error": "错误信息（如果有）"
}
```

### Cloudinary云存储API

**上传配置**:
- 云端名称: dygx9d3gi
- 上传预设: musai_unsigned
- 支持格式: jpg, png, mp3

### 阶跃星辰歌词生成API

**请求格式**:
```swift
POST /api/lyrics/generate
Content-Type: application/json

{
  "title": "歌曲标题"
}
```

**响应格式**:
```json
{
  "lyrics": "[Verse]\n生成的歌词内容\n\n[Chorus]\n副歌部分"
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

### Q: 如何配置后端服务？
A: 后端服务已部署在Render平台，地址：https://musai-backend.onrender.com
   - 如遇503错误，可能是服务休眠，等待1-2分钟后重试
   - 可使用wake_backend.sh脚本手动唤醒服务

### Q: 应用支持哪些iOS版本？
A: 应用要求iOS 17.0及以上版本，以支持最新的SwiftUI、SwiftData和StoreKit 2功能。

### Q: 钻石系统如何工作？
A: 
   - 新用户注册赠送5钻石
   - 每次创作音乐消耗10钻石
   - 周会员赠送300钻石，月会员赠送1200钻石
   - 钻石余额实时同步，支持恢复购买

### Q: 音乐生成需要多长时间？
A: 
   - 通常需要1-3分钟完成生成
   - 获取URL后立即跳转播放页面
   - 音乐文件在后台异步缓存
   - 网络状况会影响生成速度

### Q: 如何处理订阅问题？
A: 
   - 确保已登录正确的Apple ID
   - 点击"RESTORE"恢复购买
   - 兑换码兑换后可能需要重启应用
   - 订阅状态与Apple账户绑定

### Q: 生成的音乐文件存储在哪里？
A: 
   - 优先存储在本地SwiftData数据库
   - 自动备份至Cloudinary云端
   - 支持本地/云端智能切换播放
   - 可在设置中管理存储空间

### Q: 如何优化生成速度？
A: 
   - 使用清晰、主题明确的图片
   - 提供简洁的歌词内容
   - 选择合适的音乐风格参数
   - 确保网络连接稳定

## 联系信息

- 开发者: Sun1
- 项目开始时间: 2025/11/3
- 技术支持: [support@example.com]

## 版本历史

### v1.2 (2025-11-10)
**版本号**: 1.2-1110-V1
**更新说明**: 改为前后端配合实现API生成音乐;优化AI歌曲生成进程

**主要更新**:
- ✅ 后端API集成，支持Node.js SDK格式
- ✅ 优化音乐生成流程，缩短等待时间
- ✅ 完善订阅系统，支持StoreKit 2
- ✅ 修复版本显示问题
- ✅ 改进错误处理和重试机制

### v1.1 (2025-11-07)
**主要功能**:
- ✅ 基础音乐生成功能
- ✅ AI歌词生成集成
- ✅ 订阅系统初步实现
- ✅ 本地音乐存储

## 许可证

本项目采用MIT许可证，详情请参阅LICENSE文件。