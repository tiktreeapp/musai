//
//  AudioPlayerService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var hasReachedEnd = false  // 新增：标记是否播放到结尾
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var endObserver: NSObjectProtocol?  // 播放结束通知观察者
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func loadAudio(from url: URL, initialDuration: TimeInterval? = nil) {
        print("🎵 Loading new audio from URL: \(url)")
        print("  🔍 URL scheme: \(url.scheme ?? "unknown")")
        print("  📁 URL path: \(url.path)")
        print("  🌐 URL host: \(url.host ?? "none")")
        
        // 检查URL是否可访问
        if url.scheme == "file" {
            let filePath = url.path
            if FileManager.default.fileExists(atPath: filePath) {
                print("  ✅ Local file exists")
            } else {
                print("  ❌ Local file does not exist at path: \(filePath)")
            }
        }
        
        // 停止当前播放并清理状态
        stop()
        isPlaying = false
        currentTime = 0.0
        
        // 使用传入的初始时长，不设置默认时长
        if let initialDuration = initialDuration, initialDuration > 0 {
            duration = initialDuration
            print("📏 Using initial duration: \(initialDuration) seconds")
        } else {
            duration = 0.0 // 不设置默认时长，等待从音频文件获取
        }
        
        // 清理旧的观察者
        cancellables.removeAll()
        
        // 创建新的播放器和项目
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerItem?.publisher(for: \.status)
            .sink { [weak self] status in
                print("🎵 Player status changed: \(status)")
                switch status {
                case .readyToPlay:
                    // 使用AVAsset异步获取准确的音频时长
                    Task {
                        if let asset = self?.playerItem?.asset {
                            do {
                                let durationValue = try await asset.load(.duration)
                                let durationInSeconds = durationValue.seconds
                                await MainActor.run {
                                    // 如果获取到的时长有效且大于0，则更新
                                    if durationInSeconds > 0 {
                                        self?.duration = durationInSeconds
                                        print("✅ Audio ready to play, duration: \(durationInSeconds) seconds")
                                    } else {
                                        // 保持原有时长（可能是从数据库读取的）
                                        print("✅ Audio ready to play, keeping existing duration: \(self?.duration ?? 0) seconds")
                                    }
                                    
                                    // 如果两个时长都为0，可能是音频文件有问题
                                    if durationInSeconds == 0 && (self?.duration ?? 0) == 0 {
                                        print("⚠️ Warning: Audio duration is 0, file may be corrupted")
                                        self?.checkAudioFileIntegrity(url: url)
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    print("❌ Failed to load audio duration: \(error)")
                                    self?.duration = 0
                                }
                            }
                        } else {
                            await MainActor.run {
                                self?.duration = 0
                                print("✅ Audio ready to play, duration: 0 seconds")
                            }
                        }
                    }
                case .failed:
                    if let error = self?.playerItem?.error {
                        print("❌ Failed to load audio: \(error.localizedDescription)")
                        print("  🔍 Error domain: \(error._domain)")
                        print("  🔢 Error code: \(error._code)")
                    }
                case .unknown:
                    print("⏳ Player status unknown")
                @unknown default:
                    print("⚠️ Unknown player status")
                }
            }
            .store(in: &cancellables)
        
        setupTimeObserver()
        setupEndObserver()
    }
    
    func loadAudio(from urlString: String) {
        print("🎵 Loading audio from URL: \(urlString)")
        guard let url = URL(string: urlString) else { 
            print("❌ Invalid URL string: \(urlString)")
            return 
        }
        loadAudio(from: url)
    }
    
    func loadAudio(for musicTrack: MusicTrack) {
        let storageService = MusicStorageService.shared
        if let playableURL = storageService.getPlayableURL(for: musicTrack) {
            print("🎵 Loading audio from cached URL: \(playableURL.lastPathComponent)")
            // 传递保存的duration作为初始值
            loadAudio(from: playableURL, initialDuration: musicTrack.duration)
        } else {
            print("❌ No playable URL available for track: \(musicTrack.title)")
            // 如果没有可播放的URL，尝试重新从原始URL加载（可能已过期）
            if let originalURL = musicTrack.audioURL,
               let url = URL(string: originalURL) {
                print("⚠️ Attempting to load from original URL as fallback")
                loadAudio(from: url, initialDuration: musicTrack.duration)
            }
        }
    }
    
    func play() {
        guard let player = player else {
            print("❌ No player available")
            return
        }
        
        print("🎵 Play method called, duration: \(duration)")
        
        // 如果之前播放到了结尾，重置状态
        if hasReachedEnd {
            hasReachedEnd = false
            currentTime = 0
            player.seek(to: .zero)
        }
        
        // 直接尝试播放
        player.play()
        isPlaying = true
        print("▶️ Playing audio")
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        hasReachedEnd = false
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1000))
    }
    
    func skipForward(seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    private func setupTimeObserver() {
        // 使用更高精度的时间监听，每50ms回调一次
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    private func setupEndObserver() {
        // 移除之前的观察者
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // 添加播放结束通知监听
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            print("🎵 Audio playback reached end")
            self?.isPlaying = false
            self?.hasReachedEnd = true
            
            // 检查是否需要请求评论
            ReviewPromptService.shared.checkAndRequestReview()
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // 检查音频文件完整性
    private func checkAudioFileIntegrity(url: URL) {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                print("📁 Audio file size: \(fileSize) bytes")
                if fileSize < 1024 {
                    print("⚠️ Warning: Audio file is very small (\(fileSize) bytes), may be corrupted")
                }
            }
        } catch {
            print("❌ Failed to get audio file info: \(error)")
        }
    }
}

extension CMTime {
    var seconds: TimeInterval {
        return CMTimeGetSeconds(self)
    }
}