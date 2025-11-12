//
//  ReviewPromptService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/10.
//

import Foundation
import StoreKit

@MainActor
final class ReviewPromptService {
    static let shared = ReviewPromptService()
    
    // 记录播放次数
    private var playCount: Int {
        get { UserDefaults.standard.integer(forKey: "reviewPlayCount") }
        set { UserDefaults.standard.set(newValue, forKey: "reviewPlayCount") }
    }
    
    // 记录是否已经请求过评论
    private var hasRequestedReview: Bool {
        get { UserDefaults.standard.bool(forKey: "hasRequestedReview") }
        set { UserDefaults.standard.set(newValue, forKey: "hasRequestedReview") }
    }
    
    // 记录版本号
    private var lastReviewedVersion: String? {
        get { UserDefaults.standard.string(forKey: "lastReviewedVersion") }
        set { UserDefaults.standard.set(newValue, forKey: "lastReviewedVersion") }
    }
    
    private init() {}
    
    // 检查是否应该请求评论（在播放完成时调用）
    func checkAndRequestReview() {
        // 如果已经请求过评论，不再显示
        if hasRequestedReview {
            return
        }
        
        // 增加播放次数
        playCount += 1
        print("📊 Review play count: \(playCount)")
        
        // 检查是否在目标播放次数中
        let targetCounts = [1, 2, 3, 5, 7, 9, 11]
        if targetCounts.contains(playCount) {
            print("🎯 Target play count reached: \(playCount)")
            requestReview()
        }
    }
    
    // 请求评论
    private func requestReview() {
        // 检查当前版本是否已经评论过
        let currentVersion = AppVersion.current
        
        if lastReviewedVersion == currentVersion {
            print("📝 Already reviewed for version \(currentVersion)")
            return
        }
        
        // 延迟一小段时间，确保 App Store 连接已经建立
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 使用SKStoreReviewController请求评论
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                
                // 延迟检查是否成功（3秒后）
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    // 如果没有成功标记（可能用户取消了或版本未同步），不自动标记
                    // 让用户下次播放完成时再尝试
                    print("📝 Review request completed for version \(currentVersion)")
                }
                
                // 标记已请求评论（避免重复请求）
                self.hasRequestedReview = true
                self.lastReviewedVersion = currentVersion
                
                print("📝 Review requested for version \(currentVersion)")
            } else {
                print("⚠️ No UIWindowScene available for review request")
                // 回退到 App Store 页面
                self.fallbackToAppStore()
            }
        }
    }
    
    private func fallbackToAppStore() {
        // 优先使用 itms-apps 协议
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id6754842768?action=write-review") {
            UIApplication.shared.open(url) { success in
                if success {
                    print("📝 Opened App Store review page (itms-apps)")
                } else {
                    // 备用方案：使用 https
                    self.openHTTPSReviewLink()
                }
            }
        }
    }
    
    private func openHTTPSReviewLink() {
        if let url = URL(string: "https://apps.apple.com/app/id6754842768?action=write-review") {
            UIApplication.shared.open(url)
            print("📝 Falling back to App Store review page (HTTPS)")
        }
    }
    
    // 重置计数（用于测试）
    func resetCount() {
        playCount = 0
        hasRequestedReview = false
        lastReviewedVersion = nil
        print("🔄 Review count reset")
    }
}