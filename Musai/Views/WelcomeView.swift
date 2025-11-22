//
//  WelcomeView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/8.
//

import SwiftUI
import AVFoundation
import AVKit
import StoreKit

struct WelcomeView: View {
    @State private var showMainView = false
    @State private var showVideoPlayer = true
    @State private var videoURL: URL?
    @State private var isAnimating = false
    @State private var player: AVPlayer?
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var timeLeft: String = "00:60"
    @State private var timer: Timer?
    @State private var showCloseButton: Bool = false
    @State private var marqueeTexts = [
        "Alex got 40% 🎁 Premium",
        "Sam got 40% 🎁 Premium", 
        "Taylor got 40% 🎁 Premium",
        "Jordan got 40% 🎁 Premium",
        "Casey got 40% 🎁 Premium",
        "Riley got 40% 🎁 Premium",
        "Quinn got 40% 🎁 Premium",
        "Morgan got 40% 🎁 Premium",
        "Drew got 40% 🎁 Premium",
        "Jamie got 40% 🎁 Premium"
    ]
    @State private var currentIndex = 0
    @State private var marqueeOffset: CGFloat = 0
    
    enum SubscriptionPlan {
        case weekly
        case monthly
    }
    
    private func selectRandomVideo() {
        // 从3个视频文件中随机选择一个
        let videoFiles = ["intro1", "intro2", "intro3"]
        var foundURL: URL?
        var selectedVideo: String?
        
        // 首先尝试随机选择的视频
        let randomVideo = videoFiles.randomElement() ?? "intro1"
        print("🎲 Randomly selected video: \(randomVideo)")
        
        if let url = Bundle.main.url(forResource: randomVideo, withExtension: "mp4") {
            foundURL = url
            selectedVideo = randomVideo
            print("✅ Found random video URL: \(url) (selected: \(randomVideo))")
        } else {
            // 如果随机选择的视频不存在，尝试其他视频
            print("⚠️ Random video not found: \(randomVideo), trying other videos...")
            
            for video in videoFiles {
                if let url = Bundle.main.url(forResource: video, withExtension: "mp4") {
                    foundURL = url
                    selectedVideo = video
                    print("✅ Found fallback video URL: \(url) (fallback: \(video))")
                    break
                }
            }
        }
        
        if let url = foundURL {
            videoURL = url
        } else {
            print("❌ No video files found in bundle")
            videoURL = nil
        }
    }
    
    var body: some View {
        ZStack {
            // 视频背景
            if showVideoPlayer, let videoURL = videoURL {
                AVPlayerViewControllerWrapper(videoURL: videoURL, onPlayerCreated: { createdPlayer in
                    player = createdPlayer
                })
                    .ignoresSafeArea()
            } else {
                // 如果视频不可用，显示黑色背景
                Color.black.ignoresSafeArea()
            }
            
            // 半透明覆盖层
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            Gradient.Stop(color: Color.black.opacity(0.3), location: 0.0),
                            Gradient.Stop(color: Color.black.opacity(0.7), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
            
            // 左上角关闭按钮
            HStack {
                Button(action: {
                    // 停止视频播放，确保完全关闭音频
                    player?.pause()
                    player?.replaceCurrentItem(with: nil)
                    // 确保视频控制器停止播放
                    showVideoPlayer = false
                    // 跳转到主页面
                    showMainView = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.green.opacity(0.5))  // 50% 透明度
                        .font(.system(size: 12, weight: .bold))  // 字号减半，从24到12
                        .padding(6)  // padding减半，从12到6
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .opacity(showCloseButton ? 1.0 : 0.0)
                .padding(.top, 10)
                .padding(.leading, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)  // 确保在左上角
            
            // 订阅信息内容
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
                
                // 主标题
                VStack(spacing: 8) {  // 减小间距
                    Text("Create music you like")
                        .font(.system(size: 32, weight: .bold)) // 字号减小4像素，从36到32
                        .foregroundColor(.white) // 改为白色
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .shadow(color: .black, radius: 0, x: 2, y: 2) // 黑色阴影，距离2像素，右下45度
                    
                    HStack {
                        HStack {
                            Text("🎁")
                                .font(.system(size: 18, weight: .medium))
                            
                            Text("One time 40% OFF  ")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black) // 改为黑色
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white) // 黑色文字需要白色背景
                        .cornerRadius(20)
                        
                        HStack(spacing: 2) {
                            Text("⏰ ")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text(timeLeft)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red) // 红字
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white) // 白色背景
                        .cornerRadius(20)
                    }
                    
                    // 跑马灯文本
                    ZStack {
                        Text(marqueeTexts[currentIndex])
                            .font(.system(size: 14))  // 较小的字号
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.3))  // 半透明背景
                            .cornerRadius(10)
                            .offset(x: marqueeOffset)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 30)
                    .clipped()
                }
                .offset(y: 60) // 下移60像素
                
                Spacer()
                
                // 订阅计划选择
                VStack(spacing: 20) {
                    // 计划特性
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
                    
                    // 计划选择按钮
                    HStack(spacing: 20) {
                        SubscriptionPlanButton(
                            title: "$4.99/week",
                            subtitle: "Weekly",
                            isSelected: selectedPlan == .weekly
                        ) {
                            selectedPlan = .weekly
                        }
                        
                        SubscriptionPlanButton(
                            title: "$2.99/week",
                            subtitle: "Monthly",
                            isSelected: selectedPlan == .monthly,
                            hasDiscount: true,
                            discountText: "40% OFF"
                        ) {
                            selectedPlan = .monthly
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 获取访问权限按钮
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
                    
                    // 无承诺文本
                    Text("No Commitment - Cancel Anytime")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.top, -8)
                    
                    // 底部链接
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
        .onAppear {
            print("🎬 WelcomeView appeared with subscription info")
            // 每次视图出现时重新随机选择视频
            selectRandomVideo()
            // 加载订阅产品
            Task {
                await subscriptionManager.fetchProducts()
            }
            // 启动倒计时
            startTimer()
            // 10秒后显示关闭按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                showCloseButton = true
            }
            // 启动跑马灯动画
            startMarqueeAnimation()
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainTabView()
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
    
    private func startTimer() {
        var totalSeconds = 60 // 从60秒开始倒计时
        
        // 立即更新时间显示
        updateTimeLeft(totalSeconds)
        
        // 创建计时器，每秒更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            totalSeconds -= 1
            
            if totalSeconds >= 0 {
                self.updateTimeLeft(totalSeconds)
            } else {
                // 倒计时结束，可以在这里添加结束逻辑
                self.timer?.invalidate()
            }
        }
    }
    
    private func updateTimeLeft(_ totalSeconds: Int) {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        self.timeLeft = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startMarqueeAnimation() {
        // 设置初始偏移
        marqueeOffset = UIScreen.main.bounds.width
        
        // 创建定时器实现跑马灯效果
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            self.marqueeOffset -= 2
            
            // 当文本完全移出屏幕时，重置位置并切换到下一个文本
            if self.marqueeOffset < -self.getTextWidth(self.marqueeTexts[self.currentIndex]) {
                self.currentIndex = (self.currentIndex + 1) % self.marqueeTexts.count
                self.marqueeOffset = UIScreen.main.bounds.width
            }
        }
    }
    
    private func getTextWidth(_ text: String) -> CGFloat {
        // 使用NSAttributedString来精确计算文本宽度
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString.size().width
    }
}



struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
    let videoURL: URL
    let onPlayerCreated: (AVPlayer?) -> Void
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        print("🎬 Creating AVPlayerViewController with URL: \(videoURL)")
        print("🎬 Video filename: \(videoURL.lastPathComponent)")
        
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.allowsPictureInPicturePlayback = false
        controller.entersFullScreenWhenPlaybackBegins = true
        
        // 回调玩家实例
        onPlayerCreated(player)
        
        // 检查视频资产
        let asset = AVAsset(url: videoURL)
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                switch status {
                case .loaded:
                    print("✅ Video asset is playable")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        controller.player?.play()
                    }
                case .failed:
                    print("❌ Video asset failed to load: \(error?.localizedDescription ?? "Unknown error")")
                default:
                    print("⚠️ Video asset loading status: \(status)")
                }
            }
        }
        
        // 循环播放
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: controller.player?.currentItem,
            queue: .main
        ) { _ in
            print("🔄 Video ended, restarting")
            controller.player?.seek(to: .zero)
            controller.player?.play()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // 确保视频正在播放
        if uiViewController.player?.rate == 0 {
            print("🔄 Restarting video playback")
            uiViewController.player?.play()
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        // 清理通知观察者
        NotificationCenter.default.removeObserver(uiViewController)
        uiViewController.player?.pause()
        uiViewController.player?.replaceCurrentItem(with: nil) // 完全停止播放
        print("🎬 AVPlayerViewController dismantled and video stopped")
    }
}

#Preview {
    WelcomeView()
}