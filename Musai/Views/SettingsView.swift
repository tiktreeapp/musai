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
                        NavigationLink(destination: SubscriptionView()) {
                            HStack {
                                Image(systemName: "crown")
                                Text("Go Premium")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
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
                                    .foregroundColor(Theme.primaryColor)
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
                                if !hasReviewedToday {
                                    HStack {
                                        Text("💎")
                                            .font(.system(size: 12))
                                        Text("+3")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(Theme.primaryColor)
                                }
                            }
                        }
                        .foregroundColor(Theme.textColor)
                    }
                    
                    
                    
                    Section("About") {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Version")
                            Spacer()
                            Text("1.1.0")
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        
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
        }
    }
    
    private func checkDailyRewardStatus() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 检查分享奖励
        if let lastShareDate = UserDefaults.standard.object(forKey: "lastShareRewardDate") as? Date {
            let lastShareDay = Calendar.current.startOfDay(for: lastShareDate)
            hasSharedToday = today <= lastShareDay
        }
        
        // 检查评论奖励
        if let lastReviewDate = UserDefaults.standard.object(forKey: "lastReviewRewardDate") as? Date {
            let lastReviewDay = Calendar.current.startOfDay(for: lastReviewDate)
            hasReviewedToday = today <= lastReviewDay
        }
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
        if let url = URL(string: "https://apps.apple.com/app/id6454842768?action=write-review") {
            UIApplication.shared.open(url) { success in
                if success {
                    // 延迟检查，给用户时间完成评论
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        giveReviewReward()
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
    }
    
    private func giveReviewReward() {
        guard !hasReviewedToday else { return }
        
        subscriptionManager.addDiamonds(3)
        hasReviewedToday = true
        UserDefaults.standard.set(Date(), forKey: "lastReviewRewardDate")
        print("💎 Review reward: +3 diamonds")
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
}

#Preview {
    SettingsView()
}