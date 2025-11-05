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
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
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
    
    func loadAudio(from url: URL) {
        print("🎵 Loading new audio from URL: \(url)")
        
        // 停止当前播放并清理状态
        stop()
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        
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
                    self?.duration = self?.playerItem?.duration.seconds ?? 0
                    print("✅ Audio ready to play, duration: \(self?.duration ?? 0)")
                case .failed:
                    if let error = self?.playerItem?.error {
                        print("❌ Failed to load audio: \(error.localizedDescription)")
                    }
                case .unknown:
                    print("⏳ Player status unknown")
                @unknown default:
                    print("⚠️ Unknown player status")
                }
            }
            .store(in: &cancellables)
        
        setupTimeObserver()
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
            loadAudio(from: playableURL)
        } else {
            print("❌ No playable URL available for track: \(musicTrack.title)")
        }
    }
    
    func play() {
        guard let player = player else {
            print("❌ No player available")
            return
        }
        
        switch player.currentItem?.status {
        case .readyToPlay:
            player.play()
            isPlaying = true
            print("▶️ Playing audio")
        case .failed:
            print("❌ Cannot play: player item failed")
        case .unknown:
            print("⏳ Cannot play: player status unknown")
        case .none:
            print("❌ Cannot play: no player item")
        @unknown default:
            print("⚠️ Unknown player status")
        }
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
        let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

extension CMTime {
    var seconds: TimeInterval {
        return CMTimeGetSeconds(self)
    }
}