//
//  AIMusicView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import PhotosUI
import SwiftData
import StoreKit

struct AIMusicView: View {
    @State private var showingSettings = false
    @State private var showingSubscription = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Banner Section
                    BannerView()
                        .padding(.top, -36)  // 上移36像素
                    
                    // AI Music Section
                    AIMusicSection()
                    
                    // Steps Section
                    StepsView()
                        
                        // Start Button
                        StartButtonView()
                            .padding(.horizontal)
                            .padding(.top, 20)
                }
                .padding(.vertical, 48)  // 增加12像素 (20+12=32)
            }
            .musaiBackground()
            .navigationTitle("AI Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSubscription = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                            Text(subscriptionManager.currentSubscriptionType != .none ? 
                                (subscriptionManager.currentSubscriptionType == .weekly ? "Weekly" : "Monthly") : 
                                "Premium")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.backgroundColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2) // 减少垂直padding到2px
                        .background(Theme.primaryColor)
                        .cornerRadius(16)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
}

struct BannerView: View {
    var body: some View {
        Image("Banner-01")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 225)
    }
}

struct StepsView: View {
    let steps = [
        StepItem(number: 1, title: "Upload a photo", description: "Choose an image inspires your music"),
        StepItem(number: 2, title: "Input Music content", description: "Enter title and AI Lyrics or Own Lyrics"),
        StepItem(number: 3, title: "Select Options", description: "Choose style,mode,instrumentation,..."),
        StepItem(number: 4, title: "Tap Start", description: "Create your unique AI-generated music")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textColor)
            
            VStack(spacing: 12) {
                ForEach(steps, id: \.number) { step in
                    StepRowView(step: step)
                }
            }
        }
        .padding(.horizontal, 36)  // 增加12像素 (24+12=36)
    }
}

struct StepItem {
    let number: Int
    let title: String
    let description: String
}

struct StepRowView: View {
    let step: StepItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.primaryColor)
                    .frame(width: 28, height: 28)
                
                Text("\(step.number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.backgroundColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textColor)
                
                Text(step.description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryTextColor)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct StartButtonView: View {
    @State private var isAnimating = false
    @State private var showingCreateView = false
    @StateObject private var musicService = MusicGenerationService()
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
            
            // Wake up backend service when user taps Start
            Task {
                await musicService.wakeUpBackendIfNeeded()
            }
            
            // Navigate to Create view
            showingCreateView = true
        }) {
            HStack {
                Text("Start")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.backgroundColor)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.backgroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.primaryColor)
            .cornerRadius(28)
            .scaleEffect(isAnimating ? 0.95 : 1.0)
            .padding(.horizontal, 50)  // 占据80%宽度 (左右各10%)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCreateView) {
            CreateView()
        }
    }
}

struct AIMusicSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MusicTrack.createdAt, order: .reverse) private var musicTracks: [MusicTrack]
    @State private var selectedTrack: MusicTrack?
    @StateObject private var storageService = MusicStorageService.shared
    @State private var isUploadingToCloud = false
    @State private var uploadProgress: Double = 0.0
    
    // Cloudinary配置
    private let cloudinaryCloudName = "dygx9d3gi"
    private let cloudinaryUploadPreset = "musai_unsigned"
    
    // 云端歌曲数据 - 默认为空，会在应用启动时检查或上传
    @State private var cloudTracks: [MusicTrack] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Music")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textColor)
            
            if displayTracks.isEmpty {
                // 空状态或上传状态
                VStack(spacing: 12) {
                    if isUploadingToCloud {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Uploading songs to cloud...")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        
                        Text("\(Int(uploadProgress * 100))% complete")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryTextColor.opacity(0.8))
                    } else {
                        HStack {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.secondaryTextColor)
                            
                            Text("No songs available")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        
                        if !musicTracks.isEmpty {
                            Button(action: {
                                Task {
                                    await uploadUserSongsToCloud()
                                }
                            }) {
                                Text("Upload Your Songs")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.backgroundColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.primaryColor)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text("Create your first AI music to see it here")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryTextColor.opacity(0.8))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // 歌曲列表
                LazyVStack(spacing: 12) {
                    ForEach(displayTracks, id: \.id) { track in
                        AIMusicTrackRow(track: track) {
                            selectedTrack = track
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 28)  // 增加12像素 (16+12=24)
        .onAppear {
            Task {
                await loadCloudTracks()
            }
        }
        .sheet(item: $selectedTrack) { track in
            TrackDetailView(track: track)
        }
    }
    
    // 显示的歌曲（优先云端，然后是用户自己的，最后是测试歌曲）
    private var displayTracks: [MusicTrack] {
        if !cloudTracks.isEmpty {
            return cloudTracks
        } else if !musicTracks.isEmpty {
            return Array(musicTracks.prefix(3))
        }
        return []
    }
    
    // 从云端加载歌曲
    private func loadCloudTracks() async {
        // 这里可以添加从云端获取歌曲的逻辑
        // 目前使用空数组，等待上传功能
        cloudTracks = []
    }
    
    // 上传用户歌曲到云端
    private func uploadUserSongsToCloud() async {
        isUploadingToCloud = true
        uploadProgress = 0.0
        
        do {
            let descriptor = FetchDescriptor<MusicTrack>()
            let tracks = try modelContext.fetch(descriptor)
            
            guard !tracks.isEmpty else {
                isUploadingToCloud = false
                return
            }
            
            let storageService = MusicStorageService.shared
            
            for (index, track) in tracks.enumerated() {
                uploadProgress = Double(index + 1) / Double(tracks.count)
                
                // 如果已经有云端URL，跳过
                if track.cloudinaryURL != nil {
                    continue
                }
                
                // 如果有本地文件，上传到Cloudinary
                if let localPath = track.localFilePath,
                   FileManager.default.fileExists(atPath: localPath) {
                    
                    do {
                        let cloudinaryURL = try await storageService.uploadMusicToCloudinary(musicTrack: track)
                        print("✅ Uploaded \(track.title) to Cloudinary: \(cloudinaryURL)")
                    } catch {
                        print("❌ Failed to upload \(track.title): \(error.localizedDescription)")
                    }
                }
            }
            
            // 保存云端URL到数据库
            try modelContext.save()
            
            // 将上传成功的歌曲设置为云端歌曲
            cloudTracks = tracks.filter { $0.cloudinaryURL != nil }
            
        } catch {
            print("❌ Error uploading songs to cloud: \(error.localizedDescription)")
        }
        
        isUploadingToCloud = false
    }
    
    
}

struct AIMusicTrackRow: View {
    let track: MusicTrack
    let onTap: () -> Void
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var storageService = MusicStorageService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 75x75 封面图
                ZStack {
                    if let imageData = track.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.cardBackgroundColor)
                            .frame(width: 75, height: 75)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.primaryColor)
                            )
                    }
                }
                
                // 右侧内容
                VStack(alignment: .leading, spacing: 4) {
                    // 标题
                    Text(track.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textColor)
                        .lineLimit(2)  // 支持最多两行显示
                        .fixedSize(horizontal: false, vertical: true)  // 允许垂直方向自适应
                    
                    // 风格和时间
                    HStack {
                        Text(track.style.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.primaryColor)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryTextColor)
                        
                        Text(formatDate(track.createdAt))
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                // 播放按钮
                Button(action: {
                    playTrack()
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.primaryColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.cardBackgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 使用storageService获取可播放的URL并预加载音频
            if let playableURL = storageService.getPlayableURL(for: track) {
                audioPlayer.loadAudio(from: playableURL.absoluteString)
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    private func playTrack() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            // 检查是否已经加载了正确的音频
            if audioPlayer.duration == 0 {
                // 如果还没有加载音频，则加载
                if let playableURL = storageService.getPlayableURL(for: track) {
                    audioPlayer.loadAudio(from: playableURL.absoluteString)
                }
            }
            audioPlayer.play()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    AIMusicView()
}
