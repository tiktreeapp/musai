//
//  GenerationResultView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import SwiftData

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
                        .blur(radius: 30)
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
                
                ScrollView {
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
                        
                        // Cover Image Section (1/3 of screen)
                        CoverImageSection(coverImage: coverImage, geometry: geometry)
                            .frame(height: geometry.size.height / 3)
                        
                        // Player Section with adjusted position
                        VStack(spacing: 12) { // 减小12像素间距
                            // Generation Progress
                            if !isGeneratingComplete {
                                VStack(spacing: 8) {
                                    Text("Generating Music...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.textColor)
                                    
                                    ProgressView(value: generationProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Theme.primaryColor))
                                        .frame(width: 200)
                                    
                                    Text("\(Int(generationProgress * 100))%")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.secondaryTextColor)
                                }
                                .padding()
                                .background(Theme.cardBackgroundColor)
                                .cornerRadius(12)
                            }
                            
                            PlayerSection(
                                audioPlayer: audioPlayer,
                                musicURL: musicURL,
                                isFavorite: $isFavorite,
                                onShare: { shareMusic() },
                                onToggleFavorite: { toggleFavorite() }
                            )
                        }
                        .padding(.top, 40) // 向下移动40像素
                        
                        // Song Info Section with gradient background
                        SongInfoSection(
                            title: title,
                            style: style,
                            mode: mode,
                            lyrics: parsedLyrics,
                            currentLyricIndex: $currentLyricIndex,
                            audioPlayer: audioPlayer
                        )
                        .padding(.top, 24) // 向下移动24像素
                        .frame(maxWidth: .infinity) // 宽度与屏幕一样宽
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.backgroundColor.opacity(0.1), // 10%黑色透明度
                                    Theme.backgroundColor
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .ignoresSafeArea()
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
            audioPlayer.loadAudio(from: musicURL)
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
                        .foregroundColor(Theme.secondaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.secondaryColor.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            // Scrolling Lyrics
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
                        
                        // 添加底部间距
                        Color.clear
                            .frame(height: 64)
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: currentLyricIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct PlayerSection: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    let musicURL: String
    @Binding var isFavorite: Bool
    let onShare: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress Bar with Controls
            VStack(spacing: 8) {
                HStack {
                    // Share and Favorite buttons
                    HStack(spacing: 16) {
                        Button(action: { onShare() }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 27)) // 增加50% (18 * 1.5 = 27)
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        
                        Button(action: { onToggleFavorite() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 27)) // 增加50% (18 * 1.5 = 27)
                                .foregroundColor(isFavorite ? .red : Theme.secondaryTextColor)
                        }
                    }
                    
                    // Progress slider
                    Slider(
                        value: Binding(
                            get: { audioPlayer.currentTime },
                            set: { audioPlayer.seek(to: $0) }
                        ),
                        in: 0...max(audioPlayer.duration, 1),
                        step: 0.1
                    )
                    .accentColor(Theme.primaryColor)
                    
                    // Duration text
                    Text(formatTime(audioPlayer.duration))
                        .font(.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            // Playback Controls
            HStack(spacing: 32) {
                Button(action: { audioPlayer.skipBackward() }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(Theme.textColor)
                }
                
                Button(action: { togglePlayPause() }) {
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
            
            
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
    
    private func togglePlayPause() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Helper Types and Functions
extension GenerationResultView {
    private func parseLyrics(_ lyrics: String) -> [LyricLine] {
        let lines = lyrics.components(separatedBy: .newlines)
        var parsedLines: [LyricLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                // Estimate timestamp based on line position (2 seconds per line as default)
                let timestamp = TimeInterval(index * 2)
                parsedLines.append(LyricLine(text: trimmedLine, timestamp: timestamp))
            }
        }
        
        return parsedLines
    }
    
    private func startLyricSync() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let currentTime = audioPlayer.currentTime
            
            for (index, lyric) in parsedLyrics.enumerated() {
                if currentTime >= lyric.timestamp {
                    if index != currentLyricIndex {
                        currentLyricIndex = index
                    }
                }
            }
            
            if !audioPlayer.isPlaying && currentTime >= audioPlayer.duration - 0.5 {
                timer.invalidate()
            }
        }
    }
    
    private func shareMusic() {
        // Implement share functionality with specific text
        let shareText = "So amazing song based my inspiration created by Musai https://apps.apple.com/app/id6454842768"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
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

#Preview {
    GenerationResultView(
        musicURL: "https://example.com/music.mp3",
        title: "Amazing Song",
        lyrics: "Line 1\nLine 2\nLine 3\nLine 4\nLine 5",
        style: .pop,
        mode: .joyful,
        coverImage: nil
    )
}