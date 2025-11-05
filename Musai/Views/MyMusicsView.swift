//
//  MyMusicsView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import SwiftData

struct MyMusicsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MusicTrack.createdAt, order: .reverse) private var musicTracks: [MusicTrack]
    @State private var selectedTrack: MusicTrack?
    @State private var showingTrackDetail = false
    @State private var showingSettings = false
    @State private var selectedTab: MusicTab = .history
    
    enum MusicTab: String, CaseIterable {
        case history = "History"
        case like = "Like"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                TabSelectorView(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ScrollView {
                    let filteredTracks = getFilteredTracks()
                    
                    if filteredTracks.isEmpty {
                        EmptyStateView(tab: selectedTab)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(filteredTracks) { track in
                                MusicTrackCard(track: track) {
                                    selectedTrack = track
                                    showingTrackDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .musaiBackground()
            .navigationTitle("My Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        .sheet(isPresented: $showingTrackDetail) {
            if let track = selectedTrack {
                TrackDetailView(track: track)
            }
        }
    }
    
    private func sortByDate() {
        // Already sorted by date in query
    }
    
    private func getFilteredTracks() -> [MusicTrack] {
        switch selectedTab {
        case .history:
            return musicTracks
        case .like:
            return musicTracks.filter { $0.isPlaying }
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://docs.qq.com/doc/DR2xJZkNCQU1GUGdr") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openUserAgreement() {
        if let url = URL(string: "https://docs.qq.com/doc/DR3VvQ2xZbmZFRE9p") {
            UIApplication.shared.open(url)
        }
    }
}

struct TabSelectorView: View {
    @Binding var selectedTab: MyMusicsView.MusicTab
    
    var body: some View {
        HStack(spacing: 24) {
            ForEach(MyMusicsView.MusicTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == tab ? Theme.primaryColor : Theme.secondaryTextColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == tab ? Theme.primaryColor.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyStateView: View {
    @State private var showingCreateView = false
    let tab: MyMusicsView.MusicTab
    
    init(tab: MyMusicsView.MusicTab) {
        self.tab = tab
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: tab == .history ? "music.note.list" : "heart")
                .font(.system(size: 80))
                .foregroundColor(Theme.secondaryTextColor)
            
            VStack(spacing: 8) {
                Text(tab == .history ? "No Music Yet" : "No Liked Songs")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textColor)
                
                Text(tab == .history ? "Create your first AI-generated music" : "Like songs to see them here")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            if tab == .history {
                Button(action: {
                    // Navigate to Create view
                    showingCreateView = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create Music")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.backgroundColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.primaryColor)
                    .cornerRadius(24)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingCreateView) {
                    CreateView()
                }
            }
        }
        .padding(.top, 100)
    }
}

struct MusicTrackCard: View {
    let track: MusicTrack
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Cover Image with Player Overlay
                ZStack {
                    if let imageData = track.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill) // 填充，取正方形区域
                            .frame(width: 148, height: 148) // 方形尺寸
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.cardBackgroundColor)
                            .frame(width: 148, height: 148) // 方形尺寸
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.primaryColor)
                                    
                                    Text("No Cover")
                                        .font(.caption)
                                        .foregroundColor(Theme.secondaryTextColor)
                                }
                            )
                    }
                    
                    // Player Overlay
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // Quick play action
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.primaryColor)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(x: 1) // 稍微向右偏移，使三角形居中
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.bottom, 12)
                    }
                }
                
                // Track Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textColor)
                        .lineLimit(1)
                        .padding(.leading, 6) // 向右移动6像素
                    
                    HStack {
                        Text(track.style.rawValue)
                            .font(.caption)
                            .foregroundColor(Theme.primaryColor)
                            .padding(.leading, 6) // 向右移动6像素
                        
                        Spacer()
                        
                        Text(formatDate(track.createdAt))
                            .font(.caption)
                            .foregroundColor(Theme.secondaryTextColor)
                            .padding(.trailing, 6) // 向左移动6像素
                    }
                }
                .frame(width: 136, alignment: .leading) // 减少12像素，与图片边框宽度一致
                .padding(.top, 12)
                .padding(.bottom, 16)
                .padding(.horizontal, 0) // 移除水平内边距
            }
            .frame(width: 148) // 设置整个VStack的固定宽度，与图片宽度一致
            .background(Theme.cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct TrackDetailView: View {
    let track: MusicTrack
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var isPlaying = false
    @State private var isFavorite = false
    @State private var showingDeleteAlert = false
    @State private var currentLyricIndex: Int = 0
    
    // Parse lyrics into timestamped lines
    private var parsedLyrics: [LyricLine] {
        return parseLyrics(track.lyrics)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with blurred cover image
                if let imageData = track.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
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
                        TrackCoverImageSection(track: track, geometry: geometry)
                            .frame(height: geometry.size.height / 3)
                        
                        // Player Section with adjusted position
                        VStack(spacing: 12) {
                            if let audioURL = track.audioURL {
                                TrackPlayerSection(
                                    audioPlayer: audioPlayer,
                                    audioURL: audioURL,
                                    isFavorite: $isFavorite,
                                    onShare: { shareTrack() },
                                    onToggleFavorite: { toggleFavorite() }
                                )
                            }
                        }
                        .padding(.top, 40)
                        
                        // Song Info Section with gradient background
                        TrackSongInfoSection(
                            track: track,
                            lyrics: parsedLyrics,
                            currentLyricIndex: $currentLyricIndex,
                            audioPlayer: audioPlayer
                        )
                        .padding(.top, 24)
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
                    Button(action: { shareTrack() }) {
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
            if let audioURL = track.audioURL {
                audioPlayer.loadAudio(from: audioURL)
            }
            isFavorite = track.isPlaying
            startLyricSync()
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .alert("Delete Track", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteTrack()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this track?")
        }
    }
    
    private func parseLyrics(_ lyrics: String) -> [LyricLine] {
        let lines = lyrics.components(separatedBy: .newlines)
        var parsedLines: [LyricLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
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
    
    private func toggleFavorite() {
        track.isPlaying.toggle()
        isFavorite = track.isPlaying
        do {
            try modelContext.save()
        } catch {
            print("Error updating favorite status: \(error)")
        }
    }
    
    private func shareTrack() {
        let shareText = "I created an amazing song with the Musai app https://apps.apple.com/app/id6754842768"
        
        // 获取歌曲封面
        var shareItems: [Any] = [shareText, track.title]
        if let imageData = track.imageData,
           let uiImage = UIImage(data: imageData) {
            shareItems.append(uiImage)
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
    
    private func deleteTrack() {
        modelContext.delete(track)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting track: \(error)")
        }
    }
}

struct TrackCoverImageSection: View {
    let track: MusicTrack
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            if let imageData = track.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
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

struct TrackPlayerSection: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    let audioURL: String
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

struct TrackSongInfoSection: View {
    let track: MusicTrack
    let lyrics: [LyricLine]
    @Binding var currentLyricIndex: Int
    let audioPlayer: AudioPlayerService
    
    var body: some View {
        VStack(spacing: 20) {
            // Title and Style
            VStack(spacing: 8) {
                Text(track.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textColor)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Text(track.style.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Theme.primaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.primaryColor.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text(track.mode.rawValue)
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

struct PlayerControlsView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    let audioURL: String
    @Binding var isPlaying: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { audioPlayer.currentTime },
                        set: { audioPlayer.seek(to: $0) }
                    ),
                    in: 0...max(audioPlayer.duration, 1),
                    step: 0.1
                )
                .accentColor(Theme.primaryColor)
                
                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                        .font(.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                    
                    Spacer()
                    
                    Text(formatTime(audioPlayer.duration))
                        .font(.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                }
            }
            
            // Controls
            HStack(spacing: 24) {
                Button(action: { audioPlayer.skipBackward() }) {
                    Image(systemName: "gobackward.15")
                        .font(.title3)
                        .foregroundColor(Theme.textColor)
                }
                
                Button(action: { togglePlayPause() }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.primaryColor)
                }
                
                Button(action: { audioPlayer.skipForward() }) {
                    Image(systemName: "goforward.15")
                        .font(.title3)
                        .foregroundColor(Theme.textColor)
                }
            }
        }
        .padding()
        .background(Theme.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func togglePlayPause() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
        isPlaying = audioPlayer.isPlaying
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
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
                
                List {
                    Section("Support") {
                        Button(action: {
                            shareApp()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
                        
                        Button(action: {
                            reviewApp()
                        }) {
                            HStack {
                                Image(systemName: "star")
                                Text("Review")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
                    }
                    
                    
                    
                    Section("About") {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        
                        Button(action: {
                            openUserAgreement()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Users Service")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
                        
                        Button(action: {
                            openPrivacyPolicy()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Privacy Policy")
                                Spacer()
                            }
                        }
                        .foregroundColor(Theme.textColor)
                    }
                }
            }
            .musaiBackground()
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func shareApp() {
        let shareText = "So great Musai app turned musical inspiration into a nice song. https://apps.apple.com/app/id6754842768"
        
        // 获取应用图标 - 使用更可靠的方式
        var shareItems: [Any] = [shareText]
        if let appIcon = UIImage(named: "AppIcon") {
            shareItems.append(appIcon)
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
    
    private func reviewApp() {
        if let url = URL(string: "https://apps.apple.com/app/id6454842768?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://docs.qq.com/doc/DR2xJZkNCQU1GUGdr") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openUserAgreement() {
        if let url = URL(string: "https://docs.qq.com/doc/DR3VvQ2xZbmZFRE9p") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    MyMusicsView()
}