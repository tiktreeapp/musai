//
//  GenerationResultView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Helper Functions
private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

struct GenerationResultView: View {
    let musicURL: String
    let title: String
    let lyrics: String
    let style: MusicStyle
    let mode: MusicMode
    let coverImage: UIImage?
    
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var currentLyricIndex: Int = 0
    @State private var isFavorite: Bool = false
    @State private var generationProgress: Double = 0.0
    @State private var isGeneratingComplete = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Parse lyrics into timestamped lines
    private var parsedLyrics: [LyricLine] {
        return parseLyrics(lyrics)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with blurred cover image
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: 15)
                        .opacity(0.6)
                }
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.backgroundColor.opacity(0.3),
                        Theme.backgroundColor.opacity(0.7),
                        Theme.backgroundColor
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                VStack(spacing: 0) {
                    // Pull Bar
                    HStack {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Theme.secondaryTextColor.opacity(0.5))
                            .frame(width: 36, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    
                    // Cover Image Section
                    CoverImageSection(coverImage: coverImage, geometry: geometry)
                        .frame(height: geometry.size.height / 3)
                    
                    // Song Info Section with lyrics
                    SongInfoSection(
                        title: title,
                        style: style,
                        mode: mode,
                        lyrics: parsedLyrics,
                        currentLyricIndex: $currentLyricIndex,
                        audioPlayer: audioPlayer
                    )
                    .padding(.top, 24)
                    .layoutPriority(1)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    // Player Section - 置底，有独立黑色背景
                    VStack(spacing: 0) {
                        // Share and Favorite buttons
                        HStack(spacing: 32) {
                            Button(action: { shareMusic() }) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.secondaryTextColor)
                            }
                            
                            Button(action: { toggleFavorite() }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(isFavorite ? .red : Theme.secondaryTextColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        // Progress Bar
                        VStack(spacing: 0) {
                            CustomSlider(
                                value: Binding(
                                    get: { audioPlayer.currentTime },
                                    set: { audioPlayer.seek(to: $0) }
                                ),
                                range: 0...max(audioPlayer.duration, 1),
                                step: 0.1
                            )
                            
                            HStack {
                                Text(formatTime(audioPlayer.currentTime))
                                    .font(.caption)
                                    .foregroundColor(Theme.secondaryTextColor)
                                
                                Spacer()
                                
                                // App icon and Musai text
                                HStack(spacing: 4) {
                                    Image("AppIcon-120")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 16, height: 16)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    
                                    Text("Musai")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Text(formatTime(audioPlayer.duration))
                                    .font(.caption)
                                    .foregroundColor(Theme.secondaryTextColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Playback Controls
                        HStack(spacing: 40) {
                            Button(action: { audioPlayer.skipBackward() }) {
                                Image(systemName: "gobackward.15")
                                    .font(.title2)
                                    .foregroundColor(Theme.textColor)
                            }
                            
                            Button(action: { 
                                if audioPlayer.isPlaying {
                                    audioPlayer.pause()
                                } else {
                                    audioPlayer.play()
                                }
                            }) {
                                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(Theme.primaryColor)
                            }
                            
                            Button(action: { audioPlayer.skipForward() }) {
                                Image(systemName: "goforward.15")
                                    .font(.title2)
                                    .foregroundColor(Theme.textColor)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.bottom, 12)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .offset(y: 60) // 播放器组件向下移动60像素
                    .background(
                        Rectangle()
                            .fill(Color.black)
                            .offset(y: 40) // 黑色背景额外向下移动40像素
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(Theme.textColor)
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { shareMusic() }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.textColor)
                    }
                    
                    Button(action: { toggleFavorite() }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : Theme.textColor)
                    }
                }
            }
        }
        .onAppear {
            // 先尝试从缓存加载，如果没有则从远程加载并缓存
            loadAndCacheAudio()
            startLyricSync()
            
            // Simulate generation progress
            simulateGenerationProgress()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
}

struct CoverImageSection: View {
    let coverImage: UIImage?
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 148, height: 148) // 与卡片图片一致的尺寸
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 与卡片圆角一致
                    .shadow(color: Theme.primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackgroundColor)
                    .frame(width: 148, height: 148) // 与卡片图片一致的尺寸
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.primaryColor)
                    )
            }
        }
    }
}

struct SongInfoSection: View {
    let title: String
    let style: MusicStyle
    let mode: MusicMode
    let lyrics: [LyricLine]
    @Binding var currentLyricIndex: Int
    let audioPlayer: AudioPlayerService
    
    var body: some View {
        VStack(spacing: 20) {
            // Title and Style
            VStack(spacing: 8) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textColor)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Text(style.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Theme.primaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.primaryColor.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Theme.primaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.primaryColor.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text("Piano")
                        .font(.subheadline)
                        .foregroundColor(Theme.primaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.primaryColor.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            // Scrolling Lyrics with fixed height
            GeometryReader { lyricsGeometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(lyrics.enumerated()), id: \.offset) { index, lyric in
                                Text(lyric.text)
                                    .font(.system(size: index == currentLyricIndex ? 18 : 16))
                                    .fontWeight(index == currentLyricIndex ? .bold : .regular)
                                    .foregroundColor(index == currentLyricIndex ? Theme.primaryColor : Theme.secondaryTextColor)
                                    .multilineTextAlignment(.center)
                                    .id(index)
                                    .animation(.easeInOut(duration: 0.3), value: currentLyricIndex)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)  // 恢复水平内边距
                    }
                    .onChange(of: currentLyricIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .frame(height: min(lyricsGeometry.size.height, 240))  // 限制最大高度为240
            }
            .frame(maxHeight: 240)  // 设置固定最大高度
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Helper Types and Functions
extension GenerationResultView {
    private func parseLyrics(_ lyrics: String) -> [LyricLine] {
        // 尝试解析LRC格式
        if let lrcLyrics = parseLRCLyrics(lyrics) {
            return lrcLyrics
        }
        
        // 如果不是LRC格式，则使用默认解析方式
        let lines = lyrics.components(separatedBy: .newlines)
        var parsedLines: [LyricLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                // 估算时间戳，基于行索引
                let timestamp = TimeInterval(index * 2)
                parsedLines.append(LyricLine(time: timestamp, text: trimmedLine))
            }
        }
        
        return parsedLines
    }
    
    private func parseLRCLyrics(_ lyrics: String) -> [LyricLine]? {
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let lines = lyrics.components(separatedBy: .newlines)
        var result: [LyricLine] = []
        
        for line in lines {
            let nsLine = line as NSString
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) {
                // 解析分钟、秒、毫秒
                let minuteRange = match.range(at: 1)
                let secondRange = match.range(at: 2)
                let millisecondRange = match.range(at: 3)
                let textRange = match.range(at: 4)
                
                if minuteRange.location != NSNotFound,
                   secondRange.location != NSNotFound,
                   millisecondRange.location != NSNotFound,
                   textRange.location != NSNotFound {
                    
                    let minute = Double(nsLine.substring(with: minuteRange)) ?? 0
                    let second = Double(nsLine.substring(with: secondRange)) ?? 0
                    let millisecondStr = nsLine.substring(with: millisecondRange)
                    let millisecondValue = Double(millisecondStr) ?? 0
                    // 处理可能是两位或三位毫秒的情况
                    let millisecond = millisecondStr.count > 2 ? millisecondValue / 1000 : millisecondValue / 100 // 两位数按百分秒处理
                    
                    let text = nsLine.substring(with: textRange).trimmingCharacters(in: .whitespaces)
                    
                    let time = minute * 60 + second + millisecond
                    result.append(LyricLine(time: time, text: text))
                }
            }
        }
        
        return result.isEmpty ? nil : result.sorted { $0.time < $1.time }
    }
    
    private func startLyricSync() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let currentTime = audioPlayer.currentTime
            
            // 查找当前时间对应的歌词行
            var newIndex = currentLyricIndex
            for (index, lyric) in parsedLyrics.enumerated() {
                if currentTime >= lyric.time {
                    newIndex = index
                } else {
                    break  // 由于歌词是按时间排序的，找到第一个大于当前时间的歌词后就停止
                }
            }
            
            if newIndex != currentLyricIndex {
                currentLyricIndex = newIndex
            }
            
            if !audioPlayer.isPlaying && currentTime >= audioPlayer.duration - 0.5 {
                timer.invalidate()
            }
        }
    }
    
    private func shareMusic() {
        let shareText = "I created an amazing song \"\(title)\" with the Musai app https://apps.apple.com/app/id6754842768"
        
        // 获取歌曲封面
        var shareItems: [Any] = [shareText]
        if let image = coverImage {
            shareItems.append(image)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: shareItems,
            applicationActivities: nil
        )
        
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
    
    private func toggleFavorite() {
        isFavorite.toggle()
        
        // Update in database
        let fetchDescriptor = FetchDescriptor<MusicTrack>(
            predicate: #Predicate<MusicTrack> { track in track.title == title }
        )
        
        do {
            let tracks = try modelContext.fetch(fetchDescriptor)
            if let track = tracks.first {
                track.isPlaying = isFavorite
                try modelContext.save()
            }
        } catch {
            print("Error updating favorite status: \(error)")
        }
    }
    
    private func loadAndCacheAudio() {
        Task {
            do {
                // 获取远程URL
                guard let remoteURL = URL(string: musicURL) else {
                    print("❌ Invalid music URL: \(musicURL)")
                    return
                }
                
                // 保存到本地缓存
                let storageService = MusicStorageService.shared
                
                // 查找或创建MusicTrack
                let fetchDescriptor = FetchDescriptor<MusicTrack>(
                    predicate: #Predicate<MusicTrack> { track in track.title == title && track.audioURL == musicURL }
                )
                
                let existingTracks = try modelContext.fetch(fetchDescriptor)
                let musicTrack: MusicTrack
                
                if let existingTrack = existingTracks.first {
                    musicTrack = existingTrack
                    print("📝 Found existing track in database")
                } else {
                    // 创建新的MusicTrack并保存到数据库
                    musicTrack = MusicTrack(
                        title: title,
                        lyrics: lyrics,
                        style: style,
                        mode: mode,
                        speed: .medium,
                        instrumentation: .piano,
                        vocal: .noLimit,
                        imageData: coverImage?.jpegData(compressionQuality: 0.8) ?? Data(),
                        duration: 0
                    )
                    musicTrack.audioURL = musicURL
                    modelContext.insert(musicTrack)
                    try modelContext.save()
                    print("📝 Created new track in database")
                }
                
                // 缓存音频到本地
                let localURL = try await storageService.saveMusicLocally(musicURL: remoteURL, musicTrack: musicTrack)
                print("✅ Audio cached to: \(localURL.path)")
                
                // 使用本地URL加载音频
                await MainActor.run {
                    audioPlayer.loadAudio(from: localURL)
                }
            } catch {
                print("❌ Failed to cache audio, loading from remote URL: \(error)")
                // 如果缓存失败，直接使用远程URL
                await MainActor.run {
                    audioPlayer.loadAudio(from: musicURL)
                }
            }
        }
    }
    
    private func simulateGenerationProgress() {
        Task {
            print("🎵 Starting generation progress simulation")
            for i in 0..<10 {
                let progress = Double(i) / 10.0
                print("📊 Progress update: \(progress * 100)%")
                
                // Ensure valid numeric values
                let clampedProgress = max(0.0, min(1.0, progress))
                generationProgress = clampedProgress
                
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
            
            print("✅ Generation complete - progress: \(generationProgress)")
            isGeneratingComplete = true
            
            // Auto-play when generation is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🎵 Auto-playing music after generation complete")
                audioPlayer.play()
            }
        }
    }
}