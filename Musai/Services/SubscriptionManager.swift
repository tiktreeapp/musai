//
//  SubscriptionManager.swift
//  Musai
//
//  Created by Sun1 on 2025/11/7.
//

import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // Published 状态
    @Published var products: [Product] = []
    @Published var isSubscribed = false
    @Published var diamondCount = 0
    @Published var currentSubscriptionType: SubscriptionType = .none
    
    enum SubscriptionType: String {
        case none, weekly, monthly
    }
    
    // 产品ID
    private let weeklyProductID = "com.tiktreeapp.musai.weekly"
    private let monthlyProductID = "com.tiktreeapp.musai.monthly"
    
    // 钻石奖励
    private let weeklyDiamonds = 300
    private let monthlyDiamonds = 1200
    let songCost = 10
    
    private init() {
        loadDiamondCount()
        loadSubscriptionStatus()
        if diamondCount == 0 {
            diamondCount = 5
            UserDefaults.standard.set(diamondCount, forKey: "diamondCount")
        }
    }
    
    // MARK: - 获取商品信息
    func fetchProducts() async {
        print("🔍 Fetching StoreKit products...")
        do {
            let productIDs = [weeklyProductID, monthlyProductID]
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products:")
            for product in products {
                print("  - \(product.id): \(product.displayName) (\(product.displayPrice))")
            }
        } catch {
            print("❌ Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 购买订阅
    func purchase(_ product: Product) async {
        print("🛍️ Starting purchase for: \(product.id)")
        
        // 1️⃣ 检查是否已拥有订阅
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == product.id {
                print("🔁 Already subscribed to \(product.id), skipping purchase.")
                return
            }
        }
        
        // 2️⃣ 发起购买
        do {
            print("⏳ Calling product.purchase()...")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    print("✅ Transaction verified: \(transaction.id)")
                    await transaction.finish()
                    await handleSuccessfulPurchase(for: product.id)
                } else {
                    print("⚠️ Transaction unverified.")
                }
                
            case .userCancelled:
                print("⚠️ User cancelled purchase.")
                
            case .pending:
                print("⏳ Purchase pending (e.g., Family approval).")
                
            @unknown default:
                print("⚠️ Unknown purchase result: \(result)")
            }
        } catch {
            print("❌ Purchase failed with error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 成功处理逻辑
    private func handleSuccessfulPurchase(for productID: String) async {
        if productID == weeklyProductID {
            addDiamonds(weeklyDiamonds)
            currentSubscriptionType = .weekly
            isSubscribed = true
            UserDefaults.standard.set("weekly", forKey: "currentSubscriptionType")
            UserDefaults.standard.set(Date(), forKey: "subscriptionPurchaseDate")
            print("💎 Weekly subscription purchased, +\(weeklyDiamonds) diamonds.")
        } else if productID == monthlyProductID {
            addDiamonds(monthlyDiamonds)
            currentSubscriptionType = .monthly
            isSubscribed = true
            UserDefaults.standard.set("monthly", forKey: "currentSubscriptionType")
            UserDefaults.standard.set(Date(), forKey: "subscriptionPurchaseDate")
            print("💎 Monthly subscription purchased, +\(monthlyDiamonds) diamonds.")
        }
        
        await checkSubscriptionStatus()
    }
    
    
    
    // MARK: - 检查订阅状态
    func checkSubscriptionStatus() async {
        var active = false
        var type: SubscriptionType = .none
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == weeklyProductID {
                    active = true
                    type = .weekly
                } else if transaction.productID == monthlyProductID {
                    active = true
                    type = .monthly
                }
            }
        }
        
        isSubscribed = active
        currentSubscriptionType = type
        print("🔎 Subscription check → active: \(active), type: \(type)")
    }
    
    // MARK: - 恢复订阅
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            print("✅ Purchases restored successfully.")
        } catch {
            print("❌ Failed to restore purchases: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 钻石逻辑
    func canCreateSong() -> Bool { diamondCount >= songCost }
    
    func useDiamonds() {
        if diamondCount >= songCost {
            diamondCount -= songCost
            UserDefaults.standard.set(diamondCount, forKey: "diamondCount")
        }
    }
    
    private func addDiamonds(_ amount: Int) {
        diamondCount += amount
        UserDefaults.standard.set(diamondCount, forKey: "diamondCount")
    }
    
    func loadDiamondCount() {
        diamondCount = UserDefaults.standard.integer(forKey: "diamondCount")
    }
    
    func loadSubscriptionStatus() {
        let typeString = UserDefaults.standard.string(forKey: "currentSubscriptionType")
        let purchaseDate = UserDefaults.standard.object(forKey: "subscriptionPurchaseDate") as? Date ?? .distantPast
        
        let expired = purchaseDate.addingTimeInterval(7 * 24 * 60 * 60) < Date()
        if !expired, let typeString = typeString, let type = SubscriptionType(rawValue: typeString) {
            currentSubscriptionType = type
            isSubscribed = true
        } else {
            currentSubscriptionType = .none
            isSubscribed = false
        }
    }
}
