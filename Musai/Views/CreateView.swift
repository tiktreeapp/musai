//
//  CreateView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import PhotosUI
import SwiftData

struct CreateView: View {
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var title = ""
    @State private var lyrics = ""
    @State private var selectedStyle: MusicStyle = .pop
    @State private var selectedMode: MusicMode = .joyful
    @State private var selectedSpeed: MusicSpeed = .medium
    @State private var selectedInstrumentation: MusicInstrumentation = .piano
    @State private var selectedVocal: MusicVocal = .noLimit
    
    
    @State private var showingGenerationResult = false
    @State private var generatedMusicURL: String?
    
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var musicService = MusicGenerationService()
    @State private var isCreating = false
    
    
    private var canCreate: Bool {
        let hasTitle = !title.isEmpty
        let hasLyrics = !lyrics.isEmpty
        let hasImage = selectedImage != nil
        let notCreating = !isCreating
        return hasTitle && hasLyrics && hasImage && notCreating
    }
    
    private var createButtonParams: CreateButtonParams {
        CreateButtonParams(
            selectedImage: selectedImage,
            title: title,
            lyrics: lyrics,
            selectedStyle: selectedStyle,
            selectedMode: selectedMode,
            selectedSpeed: selectedSpeed,
            selectedInstrumentation: selectedInstrumentation,
            selectedVocal: selectedVocal,
            musicService: musicService,
            modelContext: modelContext,
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
                get: { lyrics },
                set: { lyrics = $0 }
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
                VStack(spacing: 24) {
                    // Image Upload Section
                    ImageUploadSection(
                        selectedImage: $selectedImage, 
                        selectedImageItem: $selectedImageItem,
                        compressImage: compressAndResizeImage
                    )
                    
                    // Title Input
                    TextInputSection(title: "Title", text: $title, placeholder: "Enter your music title")
                    
                    // Lyrics Input
                    LyricsInputSection(lyrics: $lyrics)
                    
                    // Options Section
                    OptionsSection(
                        selectedStyle: $selectedStyle,
                        selectedMode: $selectedMode,
                        selectedSpeed: $selectedSpeed,
                        selectedInstrumentation: $selectedInstrumentation,
                        selectedVocal: $selectedVocal
                    )
                    
                    // Create Button
                    CreateButtonView(params: createButtonParams, isCreating: $isCreating)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .musaiBackground()
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
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
                    lyrics: lyrics,
                    style: selectedStyle,
                    mode: selectedMode,
                    coverImage: selectedImage
                )
            }
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
        .padding(.horizontal)
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
    @Binding var lyrics: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lyrics")
                .font(.headline)
                .foregroundColor(Theme.textColor)
            
            ZStack(alignment: .topLeading) {
                // Placeholder text
                if lyrics.isEmpty && !isFocused {
                    Text("Input the lyrics with [intro][Verse][Chorus][Outro] tags")
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
                        
                        TextEditor(text: $lyrics)
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
        .padding(.horizontal)
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
        .padding()
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
    let selectedInstrumentation: MusicInstrumentation
    let selectedVocal: MusicVocal
    let musicService: MusicGenerationService
    let modelContext: ModelContext
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
        selectedInstrumentation: MusicInstrumentation,
        selectedVocal: MusicVocal,
        musicService: MusicGenerationService,
        modelContext: ModelContext,
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
        self.selectedInstrumentation = selectedInstrumentation
        self.selectedVocal = selectedVocal
        self.musicService = musicService
        self.modelContext = modelContext
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
        let result = hasTitle && hasLyrics && hasImage && notCreating
        
        print("🔍 CanCreate check: title=\(hasTitle), lyrics=\(hasLyrics), image=\(hasImage), notCreating=\(notCreating), result=\(result)")
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
            HStack {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.backgroundColor))
                        .scaleEffect(0.8)
                    Text("Creating")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.backgroundColor)
                        .padding(.leading, 8)
                } else {
                    Text("Create")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.backgroundColor)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.backgroundColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isCreating ? Theme.secondaryTextColor : (canCreate ? Theme.primaryColor : Theme.secondaryTextColor))
            .cornerRadius(28)
        }
        .disabled(!canCreate || isCreating)
        .buttonStyle(PlainButtonStyle())
        .opacity(canCreate ? 1.0 : 0.6)
    }
    
    private func createMusic() async {
        print("🎵 Starting music creation process")
        isCreating = true
        
        do {
            // Generate music with backend API
            guard let image = params.selectedImage else {
                print("❌ No image selected - cannot proceed")
                isCreating = false
                return
            }
            
            print("✓ Image validated: size=\(image.size)")
            
            let prompt = "Create a song with title '\(params.title)' and lyrics: \(params.lyrics)"
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to compress image")
                isCreating = false
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
                isCreating = false
                return
            }
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
            
            // 异步缓存音乐到本地和云端
            Task {
                await cacheMusicAfterGeneration(musicTrack: musicTrack, musicURL: musicURL)
            }
            
            // Wait 3 seconds then show result
            print("⏳ Waiting 3 seconds before showing result...")
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            params.generatedMusicURL = musicURL.absoluteString
            params.showingGenerationResult = true
            print("✅ Navigation to result page triggered")
            
        } catch {
            print("❌ Error creating music: \(error.localizedDescription)")
            if let apiError = error as? MusicGenerationError {
                print("🔍 API Error details: \(apiError.errorDescription ?? "Unknown error")")
            }
        }
        
        isCreating = false
        print("🏁 Music creation process completed")
    }
    
    private func cacheMusicAfterGeneration(musicTrack: MusicTrack, musicURL: URL) async {
        let storageService = MusicStorageService.shared
        
        do {
            // 1. 先保存到本地缓存
            print("💾 Caching music locally...")
            let localURL = try await storageService.saveMusicLocally(musicURL: musicURL, musicTrack: musicTrack)
            print("✅ Local cache saved: \(localURL.lastPathComponent)")
            
            // 2. 后台上传到Cloudinary
            print("☁️ Starting cloud upload...")
            do {
                let cloudinaryURL = try await storageService.uploadMusicToCloudinary(musicTrack: musicTrack)
                print("✅ Uploaded to Cloudinary: \(cloudinaryURL)")
            } catch {
                print("❌ Cloud upload failed: \(error.localizedDescription)")
            }
            
        } catch {
            print("❌ Cache failed: \(error.localizedDescription)")
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