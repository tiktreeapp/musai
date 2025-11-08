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
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var products: [Product] = []
    @Published var isSubscribed = false
    @Published var diamondCount = 0
    @Published var currentSubscriptionType: SubscriptionType = .none
    
    enum SubscriptionType {
        case none
        case weekly
        case monthly
    }
    
    // 产品ID
    private let weeklyProductID = "com.tiktreeapp.musai.weekly"
    private let monthlyProductID = "com.tiktreeapp.musai.monthly"
    
    // 钻石数量
    private let weeklyDiamonds = 300
    private let monthlyDiamonds = 1200
    let songCost = 10 // 每首歌曲消耗10钻石
    
    private init() {
        loadDiamondCount()
        // 如果钻石数量为0，则设置初始值为5
        if diamondCount == 0 {
            diamondCount = 5
            UserDefaults.standard.set(diamondCount, forKey: "diamondCount")
        }
    }
    
    func fetchProducts() async {
        print("🔍 Starting to fetch products...")
        print("📱 Product IDs to fetch: \(weeklyProductID), \(monthlyProductID)")
        
        do {
            let productIDs = [weeklyProductID, monthlyProductID]
            products = try await Product.products(for: productIDs)
            print("✅ Fetched \(products.count) products")
            for product in products {
                print("  - \(product.id): \(product.displayPrice)")
            }
        } catch {
            print("❌ Failed to fetch products: \(error)")
            if let storeKitError = error as? StoreKitError {
                print("🔍 StoreKitError: \(storeKitError.localizedDescription)")
            }
        }
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    
                    // 根据购买的产品添加对应的钻石
                    if product.id == weeklyProductID {
                        addDiamonds(weeklyDiamonds)
                        currentSubscriptionType = .weekly
                    } else if product.id == monthlyProductID {
                        addDiamonds(monthlyDiamonds)
                        currentSubscriptionType = .monthly
                    }
                    
                    print("✅ Purchase verified: \(transaction.productID)")
                    await checkSubscriptionStatus()
                } else {
                    print("⚠️ Transaction unverified")
                }
            case .userCancelled:
                print("⚠️ Purchase cancelled by user")
                default:
                    print("⚠️ Unknown purchase result")
            }
        } catch {
            print("❌ Purchase failed: \(error)")
        }
    }
    
    
    
    func checkSubscriptionStatus() async {
        var isActive = false
        var subscriptionType = SubscriptionType = .none
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID.hasPrefix("com.tiktreeapp.musai.") {
                isActive = true
                if transaction.productID == weeklyProductID {
                    subscriptionType = .weekly
                } else if product.id == monthlyProductID {
                    subscriptionType = .monthly
                }
                break
            }
        }
        
        isSubscribed = isActive
        if isActive {
            currentSubscriptionType = subscriptionType
        } else {
            currentSubscriptionType = .none
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
        }
    }
    
    func canCreateSong() -> Bool {
        return diamondCount >= songCost
    }
    
    func useDiamonds() {
        if diamondCount >= songCost {
            diamondCount -= songCost
            // 保存钻石数量到用户偏好设置
            UserDefaults.standard.set(diamondCount, forKey: "diamondCount")
        }
    }
    
    private func addDiamonds(_ amount: Int) {
        diamondCount += amount
        // 保存钻石数量到用户偏好设置
        UserDefaults.standard.set(diamondCount, forKey: "diamondCount")
    }
    
    func loadDiamondCount() {
        diamondCount = UserDefaults.standard.integer(forKey: "diamondCount")
    }
}
