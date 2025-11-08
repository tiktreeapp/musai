# iOS内购配置指南

## 1. 在App Store Connect中配置产品

### 登录App Store Connect
1. 访问 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择您的应用 "Musai"

### 创建内购产品
1. 选择 "功能" > "内购项目"
2. 点击 "+" 创建新的内购项目
3. 选择 "消耗型项目"

### 配置产品信息

#### Weekly产品
- **产品ID**: `com.tiktreeapp.musai.weekly`
- **参考名称**: Weekly Access
- **价格**: $4.99
- **本地化**: 添加所有需要的语言

#### Monthly产品  
- **产品ID**: `com.tiktreeapp.musai.monthly`
- **参考名称**: Monthly Access
- **价格**: $12.99
- **本地化**: 添加所有需要的语言

## 2. 在Xcode中配置

### 启用内购功能
1. 在Xcode中选择项目 target
2. 选择 "Signing & Capabilities"
3. 点击 "+ Capability"
4. 添加 "In-App Purchase"

### 配置产品
1. 在 "In-App Purchase" 部分点击 "+"
2. 添加产品ID：
   - `com.tiktreeapp.musai.weekly`
   - `com.tiktreeapp.musai.monthly`

## 3. 测试配置

### 添加测试用户
1. 在App Store Connect中，选择 "用户和访问"
2. 点击 "+" 添加沙盒测试员
3. 使用测试Apple ID登录设备设置

### 在设备上测试
1. 在iOS设置中，进入 "iTunes Store 与 App Store"
2. 退出当前Apple ID
3. 登录沙盒测试员账号

## 4. 验证配置

### 检查产品加载
启动应用后，查看控制台日志：
- 应该看到 "✅ Fetched 2 products" 消息
- 如果看到 "❌ Failed to fetch products"，检查产品ID配置

### 测试购买流程
1. 进入订阅页面
2. 选择Weekly或Monthly
3. 点击 "Get Access Now"
4. 应该弹出iOS官方购买确认窗口
5. 完成购买后，钻石数量应该增加

## 5. 常见问题

### 产品无法加载
- 检查产品ID是否完全匹配
- 确保产品已在App Store Connect中创建
- 确保产品状态为"准备提交"

### 购买窗口不弹出
- 检查是否已启用In-App Purchase capability
- 确保使用沙盒测试账号
- 检查网络连接

### 购买失败
- 检查控制台错误日志
- 确保产品价格配置正确
- 验证测试账号有支付方式