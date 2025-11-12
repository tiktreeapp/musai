//
//  CreateView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import PhotosUI
import SwiftData
import UIKit
import StoreKit
import Photos

struct CreateView: View {
    enum LyricsMode: String, CaseIterable {
        case aiLyrics = "AI Lyrics"
        case ownLyrics = "Own Lyrics"
    }
    
    // MARK: - Properties
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var title = ""
    @State private var aiLyrics = ""  // AI生成的歌词
    @State private var ownLyrics = "" // 用户自己的歌词
    @State private var selectedStyle: MusicStyle = .pop
    @State private var selectedMode: MusicMode = .joyful
    @State private var selectedSpeed: MusicSpeed = .medium
    @State private var selectedInstrumentation: MusicInstrumentation = .piano  // 恢复为单个选择
    @State private var selectedVocal: MusicVocal = .noLimit
    @State private var lyricsMode: LyricsMode = .aiLyrics
    @State private var isGeneratingLyrics = false
    @State private var hasPastedLyrics = false // 标记是否已粘贴歌词
    @State private var showingGenerationResult = false
    @State private var generatedMusicURL: String?
    @State private var showingSubscription = false  // 新增：用于显示订阅页面
    @State private var showingDailyReward = false  // 新增：每日奖励弹窗
    @State private var giftClicked = false  // 礼物是否已被点击
    @State private var giftClickableAfter = Date()  // 礼物可点击的时间
    @State private var rewardAmount = 0  // 奖励数量
    @State private var showSettingsLink = false  // 是否显示设置链接
    @State private var giftRotation = 0.0  // 礼物旋转角度
    @State private var giftRotationTimer: Timer?  // 旋转动画计时器
    @State private var hasReceivedDailyReward = false  // 今日是否已领取奖励
    @Environment(\.modelContext) private var modelContext
    @StateObject private var musicService = MusicGenerationService()
    @State private var isCreating = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    init() {
        print("🚀 CreateView initialized!")
        NSLog("CreateView initialized!")
    }
    
    private var currentLyrics: String {
        lyricsMode == .aiLyrics ? aiLyrics : ownLyrics
    }
    
    private var canCreate: Bool {
        let hasTitle = !title.isEmpty
        let hasLyrics = !currentLyrics.isEmpty
        let hasImage = selectedImage != nil
        let notCreating = !isCreating
        let notGeneratingLyrics = !isGeneratingLyrics
        
        // 在AI Lyrics模式下，即使没有歌词也可以创建（因为会自动生成）
        let canCreateInCurrentMode = lyricsMode == .aiLyrics || hasLyrics
        
        // 检查是否有足够的钻石创建歌曲
        let hasEnoughDiamonds = SubscriptionManager.shared.canCreateSong()
        
        return hasTitle && canCreateInCurrentMode && hasImage && notCreating && notGeneratingLyrics && hasEnoughDiamonds
    }
    
    private var createButtonParams: CreateButtonParams {
        CreateButtonParams(
            selectedImage: selectedImage,
            title: title,
            lyrics: currentLyrics,  // 使用当前模式的歌词
            selectedStyle: selectedStyle,
            selectedMode: selectedMode,
            selectedSpeed: selectedSpeed,
            selectedInstrumentation: selectedInstrumentation,  // 恢复为单个选择
            selectedVocal: selectedVocal,
            lyricsMode: lyricsMode,
            isGeneratingLyrics: isGeneratingLyrics,
            musicService: musicService,
            modelContext: modelContext,
            onInsufficientDiamonds: {
                showingSubscription = true
            },
            showingGenerationResult: $showingGenerationResult,
            generatedMusicURL: $generatedMusicURL,
            canCreate: Binding(
                get: { canCreate },
                set: { _ in }
            ),
            titleBinding: Binding(
                get: { title },
                set: { title = $0 }
            ),
            lyricsBinding: Binding(
                get: { 
                    lyricsMode == .aiLyrics ? aiLyrics : ownLyrics
                },
                set: { _ in }  // 不允许直接修改currentLyrics
            ),
            selectedImageBinding: Binding(
                get: { selectedImage },
                set: { selectedImage = $0 }
            ),
            isCreatingBinding: Binding(
                get: { isCreating },
                set: { isCreating = $0 }
            )
        )
    }
    
    var body: some View {
        NavigationView {
            mainContent
                .musaiBackground()
                .navigationTitle("Create")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .blur(radius: showingDailyReward ? 5 : 0)
        .animation(.easeInOut(duration: 0.3), value: showingDailyReward)
        .onChange(of: selectedImageItem) { _, newItem in
            handleImageChange(newItem)
        }
        .sheet(isPresented: $showingGenerationResult) {
            generationResultSheet
                .presentationDetents([.height(UIScreen.main.bounds.height - 52)])
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            cleanupView()
        }
        .overlay(overlayContent)
    }
    
    // MARK: - Computed Properties for Body
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                ImageUploadSection(
                    selectedImage: $selectedImage,
                    selectedImageItem: $selectedImageItem,
                    compressImage: compressAndResizeImage
                )
                
                TextInputSection(title: "Title", text: $title, placeholder: "Enter your music title")
                
                LyricsInputSection(
                    aiLyrics: $aiLyrics,
                    ownLyrics: $ownLyrics,
                    lyricsMode: $lyricsMode,
                    title: $title,
                    isGeneratingLyrics: $isGeneratingLyrics,
                    hasPastedLyrics: $hasPastedLyrics
                )
                
                OptionsSection(
                    selectedStyle: $selectedStyle,
                    selectedMode: $selectedMode,
                    selectedSpeed: $selectedSpeed,
                    selectedInstrumentation: $selectedInstrumentation,
                    selectedVocal: $selectedVocal
                )
                
                CreateButtonView(params: createButtonParams, isCreating: $isCreating)
                    .padding(.top, 24)
                
                Spacer().frame(height: 24)
                Spacer().frame(height: 48)
            }
            .padding(.horizontal, 16)
            .padding(.top, -4)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            giftButton
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            diamondCount
        }
    }
    
    private var giftButton: some View {
        // 检查当前时间是否可以显示礼物按钮
        let now = Date()
        let shouldShowGift = !giftClicked || now >= giftClickableAfter
        
        return Group {
            if shouldShowGift {
                Button(action: {
                    print("Gift button tapped - showing reward")
                    showDailyReward()
                    giftClicked = true
                    giftClickableAfter = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? Date()
                    
                    // 保存状态到UserDefaults
                    UserDefaults.standard.set(true, forKey: "giftClicked")
                    UserDefaults.standard.set(giftClickableAfter, forKey: "giftClickableAfter")
                    
                    print("🎁 Gift clicked, will reappear at: \(giftClickableAfter ?? Date())")
                }) {
                    Text("🎁")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.primaryColor)
                        .rotationEffect(.degrees(giftRotation))
                        .animation(.easeInOut(duration: 0.5), value: giftRotation)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var diamondCount: some View {
        HStack {
            Text("💎 \(SubscriptionManager.shared.diamondCount)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.textColor)
        }
    }
    
    @ViewBuilder
    private var generationResultSheet: some View {
        if let imageURL = generatedMusicURL {
            GenerationResultView(
                musicURL: imageURL,
                title: title,
                lyrics: currentLyrics,
                style: selectedStyle,
                mode: selectedMode,
                coverImage: selectedImage
            )
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        Color.black.opacity(showingDailyReward ? 0.3 : 0)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: showingDailyReward)
            .onTapGesture {
                // 点击蒙版不关闭弹窗
            }
        
        DailyRewardView(
            showingDailyReward: $showingDailyReward,
            rewardAmount: $rewardAmount,
            showSettingsLink: $showSettingsLink
        )
        .opacity(showingDailyReward ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: showingDailyReward)
    }
    
    // MARK: - Helper Methods
    private func handleImageChange(_ newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
            }
        }
    }
    
    private func setupView() {
        requestPhotoLibraryPermission()
        checkDailyRewardStatus()
        checkGiftButtonStatus()
        startGiftRotationAnimation()
    }
    
    private func cleanupView() {
        giftRotationTimer?.invalidate()
        giftRotationTimer = nil
    }
    
    private func compressAndResizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let resizedImage = renderer.image { _ in
            // Calculate aspect ratio
            let aspectRatio = image.size.width / image.size.height
            let targetAspectRatio = targetSize.width / targetSize.height
            
            var drawRect: CGRect
            
            if aspectRatio > targetAspectRatio {
                // Image is wider, scale to fit height
                let scaledWidth = targetSize.height * aspectRatio
                drawRect = CGRect(x: (targetSize.width - scaledWidth) / 2, y: 0, width: scaledWidth, height: targetSize.height)
            } else {
                // Image is taller, scale to fit width
                let scaledHeight = targetSize.width / aspectRatio
                drawRect = CGRect(x: 0, y: (targetSize.height - scaledHeight) / 2, width: targetSize.width, height: scaledHeight)
            }
            
            image.draw(in: drawRect)
        }
        
        // 进一步压缩到100KB左右
        return compressImageToTargetSize(resizedImage, targetSizeInBytes: 100 * 1024)
    }
    
    private func compressImageToTargetSize(_ image: UIImage, targetSizeInBytes: Int) -> UIImage {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        
        // 如果原始图片已经小于目标大小，直接返回
        if imageData!.count <= targetSizeInBytes {
            return image
        }
        
        // 二分法查找最佳压缩比例
        var min: CGFloat = 0.0
        var max: CGFloat = 1.0
        var lastData: Data?
        
        while max - min > 0.01 {
            compression = (min + max) / 2
            imageData = image.jpegData(compressionQuality: compression)
            
            if let data = imageData {
                if data.count < targetSizeInBytes {
                    lastData = data
                    min = compression
                } else {
                    max = compression
                }
            }
        }
        
        // 如果找到合适的压缩比例，返回压缩后的图片
        if let finalData = lastData, finalData.count <= targetSizeInBytes,
           let compressedImage = UIImage(data: finalData) {
            // print("📷 Image compressed to \(finalData.count) bytes (target: \(targetSizeInBytes) bytes)") // Reduce noise
            return compressedImage
        }
        
        // 如果压缩失败，使用最低质量
        if let lowestQualityData = image.jpegData(compressionQuality: 0.1),
           let lowestQualityImage = UIImage(data: lowestQualityData) {
            // print("📷 Image compressed to lowest quality: \(lowestQualityData.count) bytes") // Reduce noise
            return lowestQualityImage
        }
        
        // 最后的备选方案
        return image
    }
    
    private func requestPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("✅ Photo library access already authorized")
        case .limited:
            print("✅ Photo library access limited")
        case .denied, .restricted:
            print("⚠️ Photo library access denied or restricted")
        case .notDetermined:
            print("📝 Requesting photo library access...")
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("✅ Photo library access granted")
                    case .limited:
                        print("✅ Photo library access limited")
                    case .denied, .restricted:
                        print("❌ Photo library access denied or restricted")
                    case .notDetermined:
                        print("⚠️ Photo library access not determined")
                    @unknown default:
                        print("⚠️ Unknown photo library access status")
                    }
                }
            }
        @unknown default:
            print("⚠️ Unknown photo library access status")
        }
    }
    
    // MARK: - 每日奖励相关方法
    private func checkDailyRewardStatus() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastRewardDate = UserDefaults.standard.object(forKey: "lastDailyRewardDate") as? Date ?? Date.distantPast
        let lastRewardDay = Calendar.current.startOfDay(for: lastRewardDate)
        
        // 如果今天还没领取过奖励
        if today > lastRewardDay {
            hasReceivedDailyReward = false
        } else {
            hasReceivedDailyReward = true
        }
    }
    
    private func checkGiftButtonStatus() {
        // 从UserDefaults读取礼物点击状态
        giftClicked = UserDefaults.standard.bool(forKey: "giftClicked")
        
        if giftClicked {
            // 如果已点击，读取可点击时间
            giftClickableAfter = UserDefaults.standard.object(forKey: "giftClickableAfter") as? Date ?? Date()
            
            let now = Date()
            if now >= giftClickableAfter {
                // 如果已经过了6小时，重置状态
                giftClicked = false
                UserDefaults.standard.set(false, forKey: "giftClicked")
                print("🎁 Gift button is now available again!")
            } else {
                let remainingTime = giftClickableAfter.timeIntervalSince(now)
                let hours = Int(remainingTime) / 3600
                let minutes = (Int(remainingTime) % 3600) / 60
                print("🎁 Gift button will be available in \(hours)h \(minutes)m")
            }
        }
    }
    
    private func showDailyReward() {
        // 每次点击礼物都重新生成随机奖励
        let random = Double.random(in: 0...1)
        if random < 0.3 {
            rewardAmount = 1
        } else if random < 0.5 {
            rewardAmount = 2
        } else {
            rewardAmount = 3
        }
        
        // 40%几率显示设置链接
        showSettingsLink = Double.random(in: 0...1) < 0.4
        
        showingDailyReward = true
    }
    
    private func startGiftRotationAnimation() {
        // 5秒后开始第一次旋转
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.rotateGift()
        }
    }
    
    private func rotateGift() {
        // 向右旋转45度
        withAnimation(.easeInOut(duration: 0.5)) {
            giftRotation = 45
        }
        
        // 0.5秒后回到原位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.giftRotation = 0
            }
        }
        
        // 3秒后向左旋转45度
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.giftRotation = -45
            }
        }
        
        // 0.5秒后回到原位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.giftRotation = 0
            }
        }
        
        // 10秒后再次旋转
        DispatchQueue.main.asyncAfter(deadline: .now() + 14) {
            self.rotateGift()
        }
    }
}

struct ImageUploadSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageItem: PhotosPickerItem?
    let compressImage: (UIImage, CGSize) -> UIImage
    
    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                ZStack {
                    if let image = selectedImage {
                        // Compress and resize to 150x150
                        Image(uiImage: compressImage(image, CGSize(width: 150, height: 150)))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.cardBackgroundColor)
                            .frame(width: 150, height: 150)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.primaryColor)
                                    
                                    Text("Upload a photo")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.textColor)
                                }
                            )
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}

struct TextInputSection: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.textColor)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(CustomTextFieldStyle())
        }
        .padding(.horizontal, 16)  // 调整为与按钮相同的边距
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.cardBackgroundColor)
            .foregroundColor(Theme.textColor)
            .cornerRadius(12)
    }
}

struct LyricsInputSection: View {
    @Binding var aiLyrics: String
    @Binding var ownLyrics: String
    @Binding var lyricsMode: CreateView.LyricsMode
    @Binding var title: String
    @Binding var isGeneratingLyrics: Bool
    @Binding var hasPastedLyrics: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 第一行: AI Lyrics 和 Own Lyrics 模式选择
            HStack(spacing: 24) {
                ForEach(CreateView.LyricsMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            lyricsMode = mode
                        }
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(lyricsMode == mode ? Theme.primaryColor : Theme.secondaryTextColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(lyricsMode == mode ? Theme.primaryColor.opacity(0.1) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            
            // 第二行: Lyrics 标签和 Create/Paste/Clear 按钮
            HStack {
                Text("Lyrics")
                    .font(.headline)
                    .foregroundColor(Theme.textColor)
                
                Spacer()
                
                // 根据模式显示不同按钮
                if lyricsMode == .aiLyrics {
                    // AI Lyrics 模式 - Create 按钮
                    Button(action: {
                        generateAILyrics()
                    }) {
                        HStack {
                            if isGeneratingLyrics {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.primaryColor))
                                    .scaleEffect(0.5)
                            }
                            Text("Create")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Theme.primaryColor) // 绿色文本
                        .padding(4) // 上下左右都为4像素
                        .background(
                            RoundedRectangle(cornerRadius: 16) // 保持16像素圆角
                                .stroke(Theme.primaryColor, lineWidth: 1) // 绿色线框
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(title.isEmpty || isGeneratingLyrics)
                } else { // Own Lyrics mode
                    // Own Lyrics 模式 - Paste/Clear 按钮
                    Button(action: {
                        if hasPastedLyrics {
                            // Clear 操作
                            ownLyrics = ""
                            hasPastedLyrics = false
                        } else {
                            // Paste 操作
                            pasteLyrics()
                        }
                    }) {
                        Text(hasPastedLyrics ? "Clear" : "Paste")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.primaryColor) // 绿色文本
                            .padding(4) // 上下左右都为4像素
                            .background(
                                RoundedRectangle(cornerRadius: 16) // 保持16像素圆角
                                    .stroke(Theme.primaryColor, lineWidth: 1) // 绿色线框
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            ZStack(alignment: .topLeading) {
                // Placeholder text - 根据模式显示不同提示
                if (lyricsMode == .aiLyrics ? aiLyrics : ownLyrics).isEmpty && !isFocused {
                    Text(lyricsMode == .aiLyrics ? 
                         "Enter a Title and 'Create' lyrics fit your title by AI" : 
                         "Input the lyrics with [intro][Verse][Chorus][Outro] tags")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textColor.opacity(0.5))
                        .padding(16)
                        .allowsHitTesting(false)
                }
                
                // Text Editor with fixed height
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.cardBackgroundColor)
                            .frame(height: 120)
                        
                        TextEditor(text: lyricsMode == .aiLyrics ? $aiLyrics : $ownLyrics)
                            .frame(height: 120)
                            .padding(16)
                            .background(Color.clear)
                            .foregroundColor(Theme.textColor)
                            .scrollContentBackground(.hidden)
                            .focused($isFocused)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)  // 调整为与按钮相同的边距
    }
    
    
    
    private func generateAILyrics() {
        // 调用阶跃星辰API生成歌词
        print("Generating AI lyrics for title: \(title)")
        isGeneratingLyrics = true
        
        Task {
            do {
                let lyricsService = StepfunLyricsService.shared
                let generatedLyrics = try await lyricsService.generateLyrics(for: title)
                await MainActor.run {
                    self.aiLyrics = generatedLyrics
                    self.isGeneratingLyrics = false
                }
            } catch {
                print("❌ Error generating lyrics: \(error)")
                await MainActor.run {
                    self.isGeneratingLyrics = false
                    // 如果API调用失败，使用默认提示
                    self.aiLyrics = "[Verse]\nFailed to generate lyrics\n\n[Chorus]\nPlease try again"
                }
            }
        }
    }
    
    private func pasteLyrics() {
        print("Pasting lyrics from clipboard")
        // 从粘贴板获取内容
        DispatchQueue.main.async {
            let pasteboard = UIPasteboard.general
            if let clipboardContent = pasteboard.string {
                self.ownLyrics = clipboardContent.trimmingCharacters(in: .whitespacesAndNewlines)
                self.hasPastedLyrics = true
            }
        }
    }
}

struct OptionsSection: View {
    @Binding var selectedStyle: MusicStyle
    @Binding var selectedMode: MusicMode
    @Binding var selectedSpeed: MusicSpeed
    @Binding var selectedInstrumentation: MusicInstrumentation
    @Binding var selectedVocal: MusicVocal
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Options")
                .font(.headline)
                .foregroundColor(Theme.textColor)
            
            // Style Selection
            OptionPickerView(
                title: "Style",
                selection: $selectedStyle,
                options: MusicStyle.allCases
            )
            
            // Mood Selection
            OptionPickerView(
                title: "Mood",
                selection: $selectedMode,
                options: MusicMode.allCases
            )
            
            // Speed Selection
            OptionPickerView(
                title: "Speed",
                selection: $selectedSpeed,
                options: MusicSpeed.allCases
            )
            
            // Instrumentation Selection
            OptionPickerView(
                title: "Instrumentation",
                selection: $selectedInstrumentation,
                options: MusicInstrumentation.allCases
            )
            
            // Vocal Selection
            OptionPickerView(
                title: "Vocal",
                selection: $selectedVocal,
                options: MusicVocal.allCases
            )
        }
        .padding(.horizontal, 16)  // 调整为与按钮相同的边距
    }
}

struct OptionPickerView<T: CaseIterable & Hashable & RawRepresentable<String>>: View where T.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selection: T
    let options: T.AllCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selection = option
                        }) {
                            Text(option.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(selection == option ? Theme.backgroundColor : Theme.textColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selection == option ? Theme.primaryColor : Theme.cardBackgroundColor)
                                .cornerRadius(20)
                                .shadow(color: selection == option ? Theme.primaryColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct CreateButtonParams {
    let selectedImage: UIImage?
    let title: String
    let lyrics: String
    let selectedStyle: MusicStyle
    let selectedMode: MusicMode
    let selectedSpeed: MusicSpeed
    let selectedInstrumentation: MusicInstrumentation  // 恢复为单个选择
    let selectedVocal: MusicVocal
    let lyricsMode: CreateView.LyricsMode
    let isGeneratingLyrics: Bool
    let musicService: MusicGenerationService
    let modelContext: ModelContext
    
    // 回调函数，用于处理钻石不足的情况
    let onInsufficientDiamonds: () -> Void
    
    @Binding var showingGenerationResult: Bool
    @Binding var generatedMusicURL: String?
    
    // CreateView properties that need to be passed
    var canCreateBinding: Binding<Bool>
    var titleBinding: Binding<String>
    var lyricsBinding: Binding<String>
    var selectedImageBinding: Binding<UIImage?>
    var isCreatingBinding: Binding<Bool>
    
    init(
        selectedImage: UIImage?,
        title: String,
        lyrics: String,
        selectedStyle: MusicStyle,
        selectedMode: MusicMode,
        selectedSpeed: MusicSpeed,
        selectedInstrumentation: MusicInstrumentation,  // 恢复为单个选择
        selectedVocal: MusicVocal,
        lyricsMode: CreateView.LyricsMode,
        isGeneratingLyrics: Bool,
        musicService: MusicGenerationService,
        modelContext: ModelContext,
        onInsufficientDiamonds: @escaping () -> Void,
        showingGenerationResult: Binding<Bool>,
        generatedMusicURL: Binding<String?>,
        canCreate: Binding<Bool>,
        titleBinding: Binding<String>,
        lyricsBinding: Binding<String>,
        selectedImageBinding: Binding<UIImage?>,
        isCreatingBinding: Binding<Bool>
    ) {
        self.selectedImage = selectedImage
        self.title = title
        self.lyrics = lyrics
        self.selectedStyle = selectedStyle
        self.selectedMode = selectedMode
        self.selectedSpeed = selectedSpeed
        self.selectedInstrumentation = selectedInstrumentation  // 恢复为单个选择
        self.selectedVocal = selectedVocal
        self.lyricsMode = lyricsMode
        self.isGeneratingLyrics = isGeneratingLyrics
        self.musicService = musicService
        self.modelContext = modelContext
        self.onInsufficientDiamonds = onInsufficientDiamonds
        self._showingGenerationResult = showingGenerationResult
        self._generatedMusicURL = generatedMusicURL
        
        self.canCreateBinding = canCreate
        self.titleBinding = titleBinding
        self.lyricsBinding = lyricsBinding
        self.selectedImageBinding = selectedImageBinding
        self.isCreatingBinding = isCreatingBinding
    }
    
    }

struct CreateButtonView: View {
    let params: CreateButtonParams
    @Binding var isCreating: Bool
    
    init(params: CreateButtonParams, isCreating: Binding<Bool>) {
        self.params = params
        self._isCreating = isCreating
    }
    
    private var title: String {
        params.titleBinding.wrappedValue
    }
    
    private var lyrics: String {
        params.lyricsBinding.wrappedValue
    }
    
    private var selectedImage: UIImage? {
        params.selectedImageBinding.wrappedValue
    }
    
    private var canCreate: Bool {
        let hasTitle = !title.isEmpty
        let hasLyrics = !lyrics.isEmpty
        let hasImage = selectedImage != nil
        let notCreating = !isCreating
        let notGeneratingLyrics = !params.isGeneratingLyrics
        
        // 在AI Lyrics模式下，即使没有歌词也可以创建（因为会自动生成）
        let canCreateInCurrentMode = params.lyricsMode == .aiLyrics || hasLyrics
        
        // 不再检查钻石数量，在点击时再检查
        let result = hasTitle && canCreateInCurrentMode && hasImage && notCreating && notGeneratingLyrics
        
        // 完全移除 CanCreate 日志（减少噪音）
        #if DEBUG
        // CanCreate logs removed to reduce noise
        #endif
        
        return result
    }
    
    var body: some View {
        Button(action: {
            NSLog("🔘 Create button tapped!")
            NSLog("  - Can create: \(canCreate)")
            NSLog("  - Is creating: \(isCreating)")
            
            // Dismiss keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            Task {
                await createMusic()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                            .scaleEffect(0.8)
                        Text("Creating")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.white)
                            .padding(.leading, 8)
                    } else {
                        Text("Create")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.white)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isCreating ? Theme.secondaryTextColor : Theme.primaryColor)
                .cornerRadius(28)
                .padding(.horizontal, 65)  // 占据80%宽度 (左右各10%)
                
                // 钻石角标
                HStack(spacing: 2) {
                    Text("💎")
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                    Text("10")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(8)
                .offset(x: -10, y: -10)  // 调整位置到右上角
            }
        }
        .disabled(!canCreate || isCreating)
        .buttonStyle(PlainButtonStyle())
        .opacity(1.0)
    }
    
    private func createMusic() async {
        // 检查是否有足够的钻石
        if !SubscriptionManager.shared.canCreateSong() {
            print("💎 Not enough diamonds to create song, showing subscription view")
            // 调用回调函数显示订阅页面
            params.onInsufficientDiamonds()
            params.isCreatingBinding.wrappedValue = false
            return
        }
        
        print("🎵🎵🎵 STARTING MUSIC CREATION PROCESS 🎵🎵🎵")
        print("📅 Start time: \(Date())")
        print("📱 Device info: \(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)")
        print("💎 Available diamonds: \(SubscriptionManager.shared.diamondCount)")
        print("🎤 Title: \(params.title)")
        print("🎤 Lyrics length: \(params.lyrics.count) characters")
        print("🎤 Style: \(params.selectedStyle.rawValue)")
        print("🎤 Mode: \(params.selectedMode.rawValue)")
        print("🎤 Speed: \(params.selectedSpeed.rawValue)")
        print("🎤 Instrumentation: \(params.selectedInstrumentation.rawValue)")
        print("🎤 Vocal: \(params.selectedVocal.rawValue)")
        print("🎤 Image present: \(params.selectedImage != nil)")
        params.isCreatingBinding.wrappedValue = true
        
        // 使用NSLog确保日志在所有环境中都能看到
        NSLog("🎵 MUSIC CREATION STARTED - Title: \(params.title)")
        
        // 如果是AI Lyrics模式且没有歌词，则先生成歌词
        if params.lyricsMode == .aiLyrics && params.lyrics.isEmpty {
            print("📝 Generating AI lyrics before music creation")
            await generateAILyricsIfNeeded()
            print("📝 AI lyrics generation completed")
        }
        
        do {
            // Generate music with backend API
            guard let image = params.selectedImage else {
                print("❌ No image selected - cannot proceed")
                params.isCreatingBinding.wrappedValue = false
                return
            }
            
            print("✓ Image validated: size=\(image.size)")
            
            let prompt = params.lyrics  // 仅使用歌词文本生成歌曲，不包含标题
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to compress image")
                params.isCreatingBinding.wrappedValue = false
                return
            }
            print("📝 Image compressed: \(imageData.count) bytes")
            
            // Log all parameters
            print("🎼 Music Parameters:")
            print("  - Title: \(params.title)")
            print("  - Lyrics: \(params.lyrics)")
            print("  - Style: \(params.selectedStyle.rawValue)")
            print("  - Mode: \(params.selectedMode.rawValue)")
            print("  - Speed: \(params.selectedSpeed.rawValue)")
            print("  - Instrumentation: \(params.selectedInstrumentation.rawValue)")
            print("  - Vocal: \(params.selectedVocal.rawValue)")
            
            // First get prediction ID
            let step1StartTime = Date()
            print("📡 [\(DateFormatter().string(from: step1StartTime))] Step 1: Getting prediction ID...")
            NSLog("📡 MUSIC GENERATION STEP 1 START - Getting prediction ID")
            
            let predictionId = try await params.musicService.generateMusic(
                prompt: prompt,
                style: params.selectedStyle,
                mode: params.selectedMode,
                speed: params.selectedSpeed,
                instrumentation: params.selectedInstrumentation,
                vocal: params.selectedVocal,
                imageData: imageData
            )
            
            let step1EndTime = Date()
            let step1Duration = step1EndTime.timeIntervalSince(step1StartTime)
            print("✅ [\(DateFormatter().string(from: step1EndTime))] Prediction ID received: \(predictionId)")
            print("⏱️ Step 1 completed in \(String(format: "%.2f", step1Duration)) seconds")
            NSLog("✅ MUSIC GENERATION STEP 1 COMPLETE - ID: \(predictionId), Duration: \(String(format: "%.2f", step1Duration))s")
            
            // Then get the actual music URL
            let step2StartTime = Date()
            print("📡 [\(DateFormatter().string(from: step2StartTime))] Step 2: Getting music URL...")
            NSLog("📡 MUSIC GENERATION STEP 2 START - Getting music URL for ID: \(predictionId)")
            
            let musicURL = try await params.musicService.getMusicURL(for: predictionId)
            
            let step2EndTime = Date()
            let step2Duration = step2EndTime.timeIntervalSince(step2StartTime)
            let totalDuration = step2EndTime.timeIntervalSince(step1StartTime)
            
            print("✅ [\(DateFormatter().string(from: step2EndTime))] Music URL received: \(musicURL)")
            print("⏱️ Step 2 completed in \(String(format: "%.2f", step2Duration)) seconds")
            print("⏱️ Total generation time: \(String(format: "%.2f", totalDuration)) seconds")
            NSLog("✅ MUSIC GENERATION STEP 2 COMPLETE - URL: \(musicURL), Duration: \(String(format: "%.2f", step2Duration))s")
            NSLog("✅ MUSIC GENERATION COMPLETE - Total time: \(String(format: "%.2f", totalDuration))s")
            
            // 立即跳转到播放页面
            params.generatedMusicURL = musicURL.absoluteString
            params.showingGenerationResult = true
            print("✅ Navigation to result page triggered immediately")
            
            // 使用钻石
            print("💎💎💎 USING DIAMONDS FOR MUSIC CREATION 💎💎💎")
            SubscriptionManager.shared.useDiamonds()
            print("💎 Remaining diamonds: \(SubscriptionManager.shared.diamondCount)")
            
            // 重置创建状态
            params.isCreatingBinding.wrappedValue = false
            print("✅ Create button state reset")
            
            // 在后台保存和缓存音乐
            let title = params.title
            let lyrics = params.lyrics
            let selectedStyle = params.selectedStyle
            let selectedMode = params.selectedMode
            let selectedSpeed = params.selectedSpeed
            let selectedInstrumentation = params.selectedInstrumentation
            let selectedVocal = params.selectedVocal
            let modelContext = params.modelContext
            
            Task.detached {
                await saveMusicTrack(
                    title: title,
                    lyrics: lyrics,
                    style: selectedStyle,
                    mode: selectedMode,
                    speed: selectedSpeed,
                    instrumentation: selectedInstrumentation,
                    vocal: selectedVocal,
                    imageData: imageData,
                    musicURL: musicURL,
                    modelContext: modelContext
                )
            }
            
        } catch {
            let timestamp = DateFormatter().string(from: Date())
            print("❌ [\(timestamp)] Error creating music: \(error)")
            NSLog("❌ MUSIC CREATION ERROR: \(error)")
            
            // 检查错误类型并记录详细信息
            if let musicError = error as? MusicGenerationError {
                print("🎵 Music Generation Error Type: \(musicError)")
                switch musicError {
                case .invalidURL:
                    print("  - Invalid URL configured")
                case .invalidRequest:
                    print("  - Invalid request parameters")
                case .invalidResponse:
                    print("  - Invalid response from server")
                case .invalidAPIKey:
                    print("  - API key issue")
                case .rateLimitExceeded:
                    print("  - Rate limit exceeded")
                case .serverError(let code):
                    print("  - Server error with code: \(code)")
                case .invalidMusicURL:
                    print("  - Invalid music URL returned")
                case .predictionFailed(let message):
                    print("  - Prediction failed: \(message)")
                case .networkError:
                    print("  - Network error occurred")
                }
            }
            
            // 检查是否是网络错误
            if let urlError = error as? URLError {
                print("🌐 Network error details:")
                print("  - Code: \(urlError.code)")
                print("  - Localized description: \(urlError.localizedDescription)")
                print("  - Failure reason: \(urlError.localizedDescription)")
                print("  - Domain: URLError")
                
                switch urlError.code {
                case .notConnectedToInternet:
                    print("  - No internet connection")
                case .timedOut:
                    print("  - Request timed out")
                case .cannotFindHost:
                    print("  - Cannot find host")
                case .networkConnectionLost:
                    print("  - Network connection lost")
                case .badServerResponse:
                    print("  - Bad server response")
                default:
                    print("  - Other network error: \(urlError.code)")
                }
            }
            
            // 记录完整的错误堆栈
            print("📋 Error stack trace:")
            Thread.callStackSymbols.forEach { symbol in
                print("  - \(symbol)")
            }
            
            await MainActor.run {
                params.isCreatingBinding.wrappedValue = false
                print("🔄 Reset isCreating flag to false")
            }
        }
    }
    
    private func generateAILyricsIfNeeded() async {
        // This is a placeholder - actual implementation would call the lyrics service
        // For now, we'll just wait a moment to simulate the process
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    private func saveMusicTrack(
        title: String,
        lyrics: String,
        style: MusicStyle,
        mode: MusicMode,
        speed: MusicSpeed,
        instrumentation: MusicInstrumentation,
        vocal: MusicVocal,
        imageData: Data,
        musicURL: URL,
        modelContext: ModelContext
    ) async {
        print("💾 Saving music track to database...")
        
        // 获取音频时长
        let audioDuration = await getAudioDuration(from: musicURL)
        print("📏 Audio duration: \(audioDuration) seconds")
        
        await MainActor.run {
            let musicTrack = MusicTrack(
                title: title,
                lyrics: lyrics,
                style: style,
                mode: mode,
                speed: speed,
                instrumentation: instrumentation,
                vocal: vocal,
                imageData: imageData,
                duration: audioDuration
            )
            
            // Set the audioURL separately
            musicTrack.audioURL = musicURL.absoluteString
            
            modelContext.insert(musicTrack)
            
            do {
                try modelContext.save()
                print("✅ Music track saved successfully with duration: \(audioDuration) seconds")
                
                // 保存到数据库后，立即缓存音乐到本地
                Task.detached {
                    await self.cacheMusicToLocal(musicTrack: musicTrack, musicURL: musicURL)
                }
            } catch {
                print("❌ Error saving music track: \(error)")
            }
        }
    }
    
    // 缓存音乐到本地和云端
    private func cacheMusicToLocal(musicTrack: MusicTrack, musicURL: URL) async {
        print("💾 Starting to cache music to local storage...")
        
        do {
            let storageService = MusicStorageService.shared
            
            // 1. 先保存到本地缓存
            let localURL = try await storageService.saveMusicLocally(musicURL: musicURL, musicTrack: musicTrack)
            print("✅ Music cached successfully to: \(localURL.path)")
            
            // 2. 后台上传到Cloudinary（不阻塞主流程）
            print("☁️ Starting background cloud upload...")
            Task.detached {
                do {
                    let cloudinaryURL = try await storageService.uploadMusicToCloudinary(musicTrack: musicTrack)
                    print("✅ Uploaded to Cloudinary: \(cloudinaryURL)")
                } catch {
                    print("❌ Cloud upload failed: \(error.localizedDescription)")
                    // 可以在这里添加重试逻辑或记录上传失败状态
                }
            }
            
        } catch {
            print("❌ Failed to cache music locally: \(error)")
        }
    }
    
    // 获取音频文件时长
    private func getAudioDuration(from url: URL) async -> TimeInterval {
        do {
            print("🔍 Attempting to get duration for URL: \(url)")
            let asset = AVAsset(url: url)
            
            // 检查 asset 是否可播放
            let status = try await asset.load(.isReadable)
            print("🔍 Asset is readable: \(status)")
            
            let duration = try await asset.load(.duration)
            let durationInSeconds = duration.seconds
            print("📏 Retrieved duration for \(url.lastPathComponent): \(durationInSeconds) seconds")
            
            // 如果获取到的时长为0或无效，返回默认值
            if durationInSeconds.isNaN || durationInSeconds.isInfinite || durationInSeconds <= 0 {
                print("⚠️ Invalid duration (\(durationInSeconds)), using default 180 seconds")
                return 180.0
            }
            
            return durationInSeconds
        } catch {
            print("❌ Failed to get audio duration: \(error)")
            print("📍 URL scheme: \(url.scheme ?? "unknown")")
            print("📍 URL absoluteString: \(url.absoluteString)")
            // 返回默认时长而不是0
            print("⚠️ Using default duration: 180 seconds")
            return 180.0
        }
    }
}

// MARK: - 每日奖励弹窗视图
struct DailyRewardView: View {
    @Binding var showingDailyReward: Bool
    @Binding var rewardAmount: Int
    @Binding var showSettingsLink: Bool
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        ZStack {
            // 弹窗主体
            VStack(spacing: 20) {
                // 右上角关闭按钮
                HStack {
                    Spacer()
                    Button(action: {
                        showingDailyReward = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, -2) // 右移12像素 (10-28+6=-2)
                .padding(.top, -6) // 上移12像素 (10-38+22=-6)
                
                // 奖励文本
                VStack(spacing: 5) {
                    Text("Good Lucky")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    if showSettingsLink {
                        Text("Get more 💎 in Setting page")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Text("for receive 💎 \(rewardAmount) reward.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .offset(y: -10) // 上移20像素
                
                // 按钮
                Button(action: {
                    if showSettingsLink {
                        // 关闭弹窗
                        showingDailyReward = false
                    } else {
                        claimReward()
                    }
                }) {
                    Text(showSettingsLink ? "OK" : "Claim")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 112) // 宽度改为目前的一半 (28*2*0.8*0.5≈22.4，实际使用22.4*5≈112)
                        .frame(height: 38) // 高度改为目前的120% (34*1.2≈41)
                        .background(Theme.primaryColor)
                        .cornerRadius(17)
                }
                .offset(y: 0) // 上移20像素
            }
            .frame(maxWidth: 320) // 固定最大宽度为原来的80% (约375*0.8=300)
            .padding(.vertical, 24) // 高度改为18像素
            .padding(.horizontal, 12) // 减小内边距
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.black.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Theme.primaryColor, lineWidth: 2)
            )
            .zIndex(1) // 确保弹窗内容在蒙版之上
            
            // 礼物图标 - 放在绿色线框上面
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("🎁")
                        .font(.system(size: 60))
                        .offset(y: -90) // 下移20像素
                    Spacer()
                }
                Spacer()
            }
            .zIndex(2) // 确保礼物在最上层，盖住边框
        }
    }
    
    private func claimReward() {
        // 增加钻石
        subscriptionManager.addDiamonds(rewardAmount)
        
        // 记录今日已领取
        UserDefaults.standard.set(Date(), forKey: "lastDailyRewardDate")
        
        // 关闭弹窗
        showingDailyReward = false
    }
}

#Preview {
    CreateView()
}