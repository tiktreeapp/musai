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

struct CreateView: View {
    enum LyricsMode: String, CaseIterable {
        case aiLyrics = "AI Lyrics"
        case ownLyrics = "Own Lyrics"
    }
    
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
    @Environment(\.modelContext) private var modelContext
    @StateObject private var musicService = MusicGenerationService()
    @State private var isCreating = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    
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
            ScrollView {
                VStack(spacing: 24) {  // 增加组件间距离24像素
                    // Image Upload Section
                    ImageUploadSection(
                        selectedImage: $selectedImage, 
                        selectedImageItem: $selectedImageItem,
                        compressImage: compressAndResizeImage
                    )
                    
                    // Title Input
                    TextInputSection(title: "Title", text: $title, placeholder: "Enter your music title")
                    
                    // Lyrics Input - 与上方Title的距离增加24像素
                    LyricsInputSection(
                        aiLyrics: $aiLyrics,
                        ownLyrics: $ownLyrics,
                        lyricsMode: $lyricsMode,
                        title: $title,
                        isGeneratingLyrics: $isGeneratingLyrics,
                        hasPastedLyrics: $hasPastedLyrics
                    )
                    
                    // Options Section - 与上方Lyrics的距离增加24像素
                    OptionsSection(
                        selectedStyle: $selectedStyle,
                        selectedMode: $selectedMode,
                        selectedSpeed: $selectedSpeed,
                        selectedInstrumentation: $selectedInstrumentation,
                        selectedVocal: $selectedVocal
                    )
                    
                    // Create Button - 与上方Options的距离增加24像素
                    CreateButtonView(params: createButtonParams, isCreating: $isCreating)
                        .padding(.top, 24)
                    
                    // 增加24像素间距
                    Spacer()
                        .frame(height: 24)
                    
                    // 增加48像素底部间距
                    Spacer()
                        .frame(height: 48)
                }
                .padding(.horizontal, 16)
                .padding(.top, -4)  // 上移24像素 (20-24=-4)
            }
            .musaiBackground()
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Text("💎 \(SubscriptionManager.shared.diamondCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textColor)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: selectedImageItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .sheet(isPresented: $showingGenerationResult) {
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
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        
    }
    
    private func compressAndResizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
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
        
        let result = hasTitle && canCreateInCurrentMode && hasImage && notCreating && notGeneratingLyrics
        
        print("🔍 CanCreate check: title=\(hasTitle), lyrics=\(hasLyrics), image=\(hasImage), notCreating=\(notCreating), mode=\(params.lyricsMode), result=\(result)")
        return result
    }
    
    
    
    var body: some View {
        Button(action: {
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
                .background(isCreating ? Theme.secondaryTextColor : (canCreate ? Theme.primaryColor : Theme.secondaryTextColor))
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
        .opacity(canCreate ? 1.0 : 0.6)
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
            print("📡 Step 1: Getting prediction ID...")
            let predictionId = try await params.musicService.generateMusic(
                prompt: prompt,
                style: params.selectedStyle,
                mode: params.selectedMode,
                speed: params.selectedSpeed,
                instrumentation: params.selectedInstrumentation,
                vocal: params.selectedVocal,
                imageData: imageData
            )
            print("✅ Prediction ID received: \(predictionId)")
            
            // Then get the actual music URL
            print("📡 Step 2: Getting music URL...")
            let musicURL = try await params.musicService.getMusicURL(for: predictionId)
            print("✅ Music URL received: \(musicURL)")
            
            // Save to database
            guard let finalImageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to compress image for database")
                params.isCreatingBinding.wrappedValue = false
                return
            }
            // 验证音乐URL是否有效
            print("🔍 Validating music URL...")
            let (validateData, validateResponse) = try await URLSession.shared.data(from: musicURL)
            
            if let httpResponse = validateResponse as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               !validateData.isEmpty {
                print("✅ Music URL validation successful")
                
                // 创建音乐记录
                print("🎵 Creating music track record...")
                let musicTrack = MusicTrack(
                    title: params.title,
                    lyrics: params.lyrics,
                    style: params.selectedStyle,
                    mode: params.selectedMode,
                    speed: params.selectedSpeed,
                    instrumentation: params.selectedInstrumentation,
                    vocal: params.selectedVocal,
                    imageData: finalImageData
                )
                musicTrack.audioURL = musicURL.absoluteString
                
                print("💾 Saving to database...")
                params.modelContext.insert(musicTrack)
                try params.modelContext.save()
                print("✅ Saved to database successfully")
                
                // 同步缓存音乐到本地和云端
                print("💾 Caching music locally and to cloud...")
                await cacheMusicAfterGeneration(musicTrack: musicTrack, musicURL: musicURL)
                
                // Wait 3 seconds then show result
                print("⏳ Waiting 3 seconds before showing result...")
                try await Task.sleep(nanoseconds: 3_000_000_000)
                
                params.generatedMusicURL = musicURL.absoluteString
                params.showingGenerationResult = true
                print("✅ Navigation to result page triggered")
                
                // 使用钻石
                print("💎💎💎 USING DIAMONDS FOR MUSIC CREATION 💎💎💎")
                SubscriptionManager.shared.useDiamonds()
                print("💎 Remaining diamonds: \(SubscriptionManager.shared.diamondCount)")
                print("✅✅✅ MUSIC CREATION COMPLETED SUCCESSFULLY! ✅✅✅")
                print("📅 Completion time: \(Date())")
                NSLog("✅ MUSIC CREATION SUCCESS - Title: \(params.title)")
            } else {
                print("❌ Music URL validation failed")
                print("❌ Status code: \((validateResponse as? HTTPURLResponse)?.statusCode ?? -1)")
                print("❌ Response size: \(validateData.count) bytes")
                throw MusicGenerationError.invalidResponse
            }
            
        } catch {
            print("❌ Error creating music: \(error.localizedDescription)")
            print("📅 Error time: \(Date())")
            print("🔍 Error type: \(type(of: error))")
            
            if let apiError = error as? MusicGenerationError {
                print("🔍 API Error details: \(apiError.errorDescription ?? "Unknown error")")
            }
            
            if let urlError = error as? URLError {
                print("🔍 URLError details:")
                print("  - Code: \(urlError.code.rawValue)")
                print("  - Description: \(urlError.localizedDescription)")
                print("  - Failing URL: \(urlError.failingURL?.absoluteString ?? "Unknown")")
            }
            
            // 检查是否是任务取消错误
            if error is CancellationError {
                print("⚠️ Music generation was cancelled")
            }
        }
        
        params.isCreatingBinding.wrappedValue = false
        print("🏁 Music creation process completed at: \(Date())")
    }
    
    private func generateAILyricsIfNeeded() async {
        // 模拟API调用
        print("📝 Generating AI lyrics for title: \(params.title)")
        
        // 创建一个Promise来等待异步操作完成
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                // 示例歌词内容
                params.lyricsBinding.wrappedValue = "[Verse]\nThis is an AI generated song\nBased on your title: \(params.title)\n\n[Chorus]\nMusic flows like magic\nAI creates what we imagine\n\n[Bridge]\nEvery note is crafted\nWith artificial intelligence\n\n[Outro]\nEnjoy your unique creation"
                continuation.resume()
            }
        }
    }
    
    private func cacheMusicAfterGeneration(musicTrack: MusicTrack, musicURL: URL) async {
        let storageService = MusicStorageService.shared
        
        do {
            // 1. 先保存到本地缓存
            print("💾 Caching music locally...")
            let localURL = try await storageService.saveMusicLocally(musicURL: musicURL, musicTrack: musicTrack)
            print("✅ Local cache saved: \(localURL.lastPathComponent)")
            
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
            print("❌ Cache failed: \(error.localizedDescription)")
            // 记录缓存失败状态
            await MainActor.run {
                musicTrack.isCachedLocally = false
            }
        }
    }
}

struct ProgressOverlayView: View {
    let musicProgress: Double
    let uploadProgress: Double
    let isUploading: Bool
    
    var body: some View {
        ZStack {
            Theme.overlayColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(isUploading ? "Uploading Image..." : "Generating Music...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textColor)
                
                ProgressView(value: isUploading ? uploadProgress : musicProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.primaryColor))
                    .frame(width: 200)
                
                Text("\(Int((isUploading ? uploadProgress : musicProgress) * 100))%")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.secondaryTextColor)
                
                if isUploading {
                    Text("Uploading image to cloud storage...")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                } else {
                    Text("AI is creating your unique music...")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(Theme.cardBackgroundColor)
            .cornerRadius(16)
        }
    }
}

#Preview {
    CreateView()
}
