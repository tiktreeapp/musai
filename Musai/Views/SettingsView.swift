//
//  SettingsView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var hasSharedToday = false
    @State private var hasReviewedToday = false
    @State private var reviewRewardTimerActive = false
    @State private var premiumAvatars: [AvatarInfo] = []
    
    private struct AvatarInfo {
        let emoji: String
        let backgroundColor: Color
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Pull Bar
                HStack {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Theme.secondaryTextColor.opacity(0.5))
                        .frame(width: 36, height: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                List {
                    Section("Subscription") {
                        // 简化版实现，使用最基础的视图结构
                        NavigationLink(destination: SubscriptionView()) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "crown")
                                        .font(.system(size: 16))  // 默认图标大小
                                    Text("Go Premium")
                                        .font(.system(size: 24, weight: .medium))  // 改为24号字体并加粗
                                        .foregroundColor(.black)  // 改为黑色
                                    Spacer()
                                }
                                
                                // 用户购买信息 - 使用固定内容避免复杂视图
                                HStack {
                                    // 简化的头像表示，避免复杂的视图嵌套
                                    HStack(spacing: -6) {
                                        // 直接创建三个头像视图，而不是通过函数
                                        Circle()
                                            .fill(premiumAvatars.count > 0 ? premiumAvatars[0].backgroundColor : Color.blue.opacity(0.3))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Text(premiumAvatars.count > 0 ? premiumAvatars[0].emoji : "🐶")
                                                    .font(.system(size: 14))  // 改为14号字体
                                            )
                                        
                                        Circle()
                                            .fill(premiumAvatars.count > 1 ? premiumAvatars[1].backgroundColor : Color.red.opacity(0.3))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Text(premiumAvatars.count > 1 ? premiumAvatars[1].emoji : "🐱")
                                                    .font(.system(size: 14))  // 改为14号字体
                                            )
                                        
                                        Circle()
                                            .fill(premiumAvatars.count > 2 ? premiumAvatars[2].backgroundColor : Color.green.opacity(0.3))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Text(premiumAvatars.count > 2 ? premiumAvatars[2].emoji : "🦊")
                                                    .font(.system(size: 14))  // 改为14号字体
                                            )
                                    }
                                    
                                    Text("\(Int.random(in: 21...99)) users purchase 👑 last 24h")
                                        .font(.system(size: 14))  // 改为14号字体
                                        .foregroundColor(.black.opacity(0.5))  // 黑色50%透明度
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 8)  // 减少水平内边距到一半
                            .padding(.vertical, 8)    // 减少垂直内边距到一半
                        }
                        .foregroundColor(.black)  // 右侧">"改为黑色
                        // 使用listRowBackground修改背景色
                        .listRowBackground(Theme.primaryColor)
                        .frame(height: 80) // 使高度为原来的2倍
                    }
                    
                    Section("Support") {
                        Button(action: {
                            shareApp()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                                Spacer()
                                if !hasSharedToday {
                                    HStack {
                                        Text("💎")
                                            .font(.system(size: 12))
                                        Text("+2")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.white)  // 改为白色
                                }
                            }
                        }
                        .foregroundColor(Theme.textColor)
                        
                        Button(action: {
                            reviewApp()
                        }) {
                            HStack {
                                Image(systemName: "star")
                                Text("Review")
                                Spacer()
                                if !hasReviewedForCurrentVersion() || reviewRewardTimerActive {
                                    HStack {
                                        Text("💎")
                                            .font(.system(size: 12))
                                        Text("+5")  // 改为+5钻石
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.white)  // 改为白色
                                }
                            }
                        }
                        .foregroundColor(Theme.textColor)
                    }
                    
                    
                    
                    Section("About") {
                        Button(action: {
                            openUserAgreement()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Users Service")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
                        
                        Button(action: {
                            openPrivacyPolicy()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Privacy Policy")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
                    }
                }
            }
            .musaiBackground()
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            checkDailyRewardStatus()
            if premiumAvatars.isEmpty {
                premiumAvatars = generateRandomAvatars()
            }
        }
    }
    
    private func checkDailyRewardStatus() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 检查分享奖励
        if let lastShareDate = UserDefaults.standard.object(forKey: "lastShareRewardDate") as? Date {
            let lastShareDay = Calendar.current.startOfDay(for: lastShareDate)
            hasSharedToday = today <= lastShareDay
        }
        
        // 检查评论奖励（基于版本）
        // hasReviewedToday变量在版本评价场景中表示当前版本是否已经评价过
        hasReviewedToday = hasReviewedForCurrentVersion()
    }
    
    private func hasReviewedForCurrentVersion() -> Bool {
        // 获取当前版本号
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        // 获取已评价的版本号
        let reviewedVersion = UserDefaults.standard.string(forKey: "lastReviewedVersion") ?? ""
        // 如果当前版本已经被评价过，则返回true（表示已评价）
        // 如果当前版本未被评价过，则返回false（表示未评价）
        return reviewedVersion == currentVersion
    }
    
    private func shareApp() {
        let shareText = "So great Musai app turned musical inspiration into a nice song. https://apps.apple.com/app/id6754842768"
        
        // 获取应用图标 - 使用更可靠的方式
        var shareItems: [Any] = [shareText]
        if let appIcon = UIImage(named: "AppIcon") {
            shareItems.append(appIcon)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
        // 设置完成后的回调
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if completed {
                // 分享完成，给予奖励
                giveShareReward()
            }
        }
        
        // 使用正确的方式获取当前视图控制器
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // 找到当前展示的视图控制器
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                // 对于iPad，需要设置sourceView
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topViewController.view
                    popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                topViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func reviewApp() {
        // 激活45秒奖励显示计时器
        reviewRewardTimerActive = true
        
        // 45秒后检查是否需要给予奖励
        Timer.scheduledTimer(withTimeInterval: 45, repeats: false) { _ in
            // 检查是否是新版本评价
            let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
            let lastReviewedVersion = UserDefaults.standard.string(forKey: "lastReviewedVersion") ?? ""
            
            // 如果当前版本未被评价过，则给予奖励
            if lastReviewedVersion != currentVersion {
                giveReviewReward()
            }
            reviewRewardTimerActive = false
        }
        
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id6754842768?action=write-review") {
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ Successfully opened App Store review page")
                } else {
                    // 如果itms-apps协议失败，尝试使用https协议
                    if let httpsUrl = URL(string: "https://apps.apple.com/app/id6754842768?action=write-review") {
                        UIApplication.shared.open(httpsUrl)
                        print("🌐 Fallback to HTTPS App Store review page")
                    }
                }
            }
        }
    }
    
    private func giveShareReward() {
        guard !hasSharedToday else { return }
        
        subscriptionManager.addDiamonds(2)
        hasSharedToday = true
        UserDefaults.standard.set(Date(), forKey: "lastShareRewardDate")
        print("💎 Share reward: +2 diamonds")
        
        // 显示余额增加弹窗
        showAlert(title: "👏 Successfully", message: "You balance increased by 💎 2.")
    }
    
    private func giveReviewReward() {
        // 检查是否是新版本评价
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let lastReviewedVersion = UserDefaults.standard.string(forKey: "lastReviewedVersion") ?? ""
        
        // 如果当前版本未被评价过，则给予奖励
        if lastReviewedVersion != currentVersion {
            subscriptionManager.addDiamonds(5)  // 奖励5钻石
            UserDefaults.standard.set(currentVersion, forKey: "lastReviewedVersion")
            print("💎 Review reward: +5 diamonds for version \(currentVersion)")
            
            // 显示余额增加弹窗
            showAlert(title: "👏 Successfully", message: "You balance increased by 💎 5.")
        } else {
            print("📝 Already reviewed for version \(currentVersion)")
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://docs.qq.com/doc/DR2xJZkNCQU1GUGdr") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openUserAgreement() {
        if let url = URL(string: "https://docs.qq.com/doc/DR3VvQ2xZbmZFRE9p") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func generateRandomAvatars() -> [AvatarInfo] {
        let animalEmojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻"]
        
        let lightColors = [Color.red.opacity(0.5), Color.orange.opacity(0.5), Color.yellow.opacity(0.5),
                          Color.green.opacity(0.5)]
        
        var selectedAvatars: [AvatarInfo] = []
        for _ in 0..<3 {
            let randomEmoji = animalEmojis.randomElement() ?? "🐶"
            let randomColor = lightColors.randomElement() ?? Color.blue.opacity(0.3)
            selectedAvatars.append(AvatarInfo(emoji: randomEmoji, backgroundColor: randomColor))
        }
        
        return selectedAvatars
    }
    
    private func refreshPremiumAvatars() {
        premiumAvatars = generateRandomAvatars()
    }
}

#Preview {
    SettingsView()
}
