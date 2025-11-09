//
//  SubscriptionView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/7.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var purchaseCompleted = false
    
    enum SubscriptionPlan {
        case weekly
        case monthly
    }
    
    var body: some View {
        ZStack {
            // Background image with custom gradient overlay, moved up 48px and centered
            Image("ProBG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -48) // 上移48像素
                .clipped() // 确保图片居中显示
                .overlay(
                    // Custom gradient: bottom 1/4 black, then black to transparent gradient from 1/4 to 3/4
                    LinearGradient(
                        gradient: Gradient(stops: [
                            Gradient.Stop(color: Color.black, location: 0.0),
                            Gradient.Stop(color: Color.black, location: 0.25),
                            Gradient.Stop(color: Color.black.opacity(0), location: 0.75),
                            Gradient.Stop(color: Color.black.opacity(0), location: 1.0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .ignoresSafeArea()
            
            // Load products when view appears
            .task {
                await subscriptionManager.fetchProducts()
            }
            
            // Content
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
                
                Spacer()
                
                // Main title - moved down 60px
                VStack(spacing: 16) {
                    Text("Create the music you love.")
                        .font(.system(size: 36, weight: .bold)) // 字号调到36
                        .foregroundColor(.white) // 改为白色
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .shadow(color: .black, radius: 0, x: 2, y: 2) // 黑色阴影，距离2像素，右下45度
                    
                    Text("#1 AI Music Generator")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black) // 改为黑色
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white) // 黑色文字需要白色背景
                        .cornerRadius(20)
                }
                .offset(y: 60) // 下移60像素
                
                Spacer()
                
                // Subscription plans selection
                VStack(spacing: 20) {
                    // Plan features based on selection
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(getFeatures(), id: \.self) { feature in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.primaryColor)
                                
                                Text(feature)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Plan selection buttons
                    HStack(spacing: 20) {
                        SubscriptionPlanButton(
                            title: "Weekly",
                            price: getWeeklyPrice(),
                            isSelected: selectedPlan == .weekly
                        ) {
                            selectedPlan = .weekly
                        }
                        
                        SubscriptionPlanButton(
                            title: "Monthly",
                            price: getMonthlyPrice(),
                            isSelected: selectedPlan == .monthly,
                            hasDiscount: true,
                            discountText: "40% OFF"
                        ) {
                            selectedPlan = .monthly
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Get Access button
                    Button(action: {
                        purchaseSelectedPlan()
                    }) {
                        HStack {
                            Text("Get Access Now")
                                .font(.system(size: 20, weight: .bold))
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.primaryColor)
                        .cornerRadius(28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // No commitment text
                    Text("No Commitment - Cancel Anytime")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.top, -8)
                    
                    // Footer links
                    HStack(spacing: 30) {
                        Button(action: {
                            openTerms()
                        }) {
                            Text("Terms")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }) {
                            Text("RESTORE")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            openPrivacy()
                        }) {
                            Text("Privacy")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, -4)
                    .padding(.bottom, 0)
                }
            }
        }
        .navigationBarHidden(true) // 隐藏导航栏
        .onChange(of: subscriptionManager.diamondCount) { oldCount, newCount in
            if newCount > oldCount && newCount > 5 {  // 如果钻石数量增加且大于初始值
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {  // 稍微延迟，确保UI更新完成
                    dismiss()
                }
            }
        }
    }
    
    private func getFeatures() -> [String] {
        switch selectedPlan {
        case .weekly:
            return [
                "No Limit to Create AI Lyrics",
                "Get 300 💎 weekly, Create 30 songs",
                "HD Music, More Selections, Ad-Free"
            ]
        case .monthly:
            return [
                "No Limit to Create AI Lyrics",
                "Get 1200 💎 monthly, Create 120 songs",
                "HD Music, More Selections, Ad-Free"
            ]
        }
    }
    
    private func getWeeklyPrice() -> String {
        if let product = subscriptionManager.products.first(where: { $0.id == "com.tiktreeapp.musai.weekly" }) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            print("✅ Found weekly product: \(product.id), price: \(product.price)")
            return formatter.string(from: product.price as NSNumber) ?? "$4.99"
        }
        print("❌ Weekly product not found")
        return "$4.99"
    }
    
    private func getMonthlyPrice() -> String {
        if let product = subscriptionManager.products.first(where: { $0.id == "com.tiktreeapp.musai.monthly" }) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            print("✅ Found monthly product: \(product.id), price: \(product.price)")
            return formatter.string(from: product.price as NSNumber) ?? "$12.99"
        }
        print("❌ Monthly product not found")
        return "$12.99"
    }
    
    private func purchaseSelectedPlan() {
        let productID = selectedPlan == .weekly ? "com.tiktreeapp.musai.weekly" : "com.tiktreeapp.musai.monthly"
        print("🛒 Attempting to purchase product: \(productID)")
        print("📋 Total products loaded: \(subscriptionManager.products.count)")
        print("📋 Available products: \(subscriptionManager.products.map { "\($0.id) - \($0.displayPrice)" })")
        
        if let product = subscriptionManager.products.first(where: { $0.id == productID }) {
            print("✅ Found product in list, proceeding with purchase")
            print("📱 Product details: \(product.id) - \(product.displayPrice) - \(product.description)")
            
            Task {
                await subscriptionManager.purchase(product)
            }
        } else {
            print("❌ Product not found in products list")
            print("🔍 Looking for ID: \(productID)")
            print("🔍 Available IDs: \(subscriptionManager.products.map { $0.id })")
            
            // 尝试重新获取产品
            Task {
                print("🔄 Retrying to fetch products...")
                await subscriptionManager.fetchProducts()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.purchaseSelectedPlan()
                }
            }
        }
    }
    
    private func openTerms() {
        if let url = URL(string: "https://docs.qq.com/doc/DR3VvQ2xZbmZFRE9p") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacy() {
        if let url = URL(string: "https://docs.qq.com/doc/DR2xJZkNCQU1GUGdr") {
            UIApplication.shared.open(url)
        }
    }
}

struct SubscriptionPlanButton: View {
    let title: String
    let price: String
    let isSelected: Bool
    let hasDiscount: Bool
    let discountText: String
    let action: () -> Void
    
    init(title: String, price: String, isSelected: Bool, hasDiscount: Bool = false, discountText: String = "", action: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.isSelected = isSelected
        self.hasDiscount = hasDiscount
        self.discountText = discountText
        self.action = action
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.5)) // 未选中时文本50%透明度
                    
                    Text(price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.5)) // 未选中时文本50%透明度
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color.black.opacity(0.5)) // 黑色背景50%透明度
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Theme.primaryColor : Color.white.opacity(0.5), lineWidth: 2) // 未选中时白色线框50%透明度
                )
                .cornerRadius(12)
            }
            
            if hasDiscount {
                Text(discountText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
                    .offset(x: 8, y: -8)
            }
        }
    }
}

#Preview {
    SubscriptionView()
}