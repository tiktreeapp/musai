//
//  WelcomeView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/8.
//

import SwiftUI
import AVFoundation
import AVKit

struct WelcomeView: View {
    @State private var showMainView = false
    @State private var showVideoPlayer = true
    @State private var videoURL: URL?
    @State private var isAnimating = false
    @State private var player: AVPlayer?
    
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
            if showVideoPlayer, let videoURL = videoURL {
                AVPlayerViewControllerWrapper(videoURL: videoURL, onPlayerCreated: { createdPlayer in
                    player = createdPlayer
                })
                    .ignoresSafeArea()
            } else {
                // 如果视频不可用，显示黑色背景
                Color.black.ignoresSafeArea()
            }
            
            // Continue按钮
            VStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isAnimating.toggle()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAnimating = false
                    }
                    
                    // 停止视频播放
                    print("⏹️ Stopping video playback")
                    player?.pause()
                    
                    // 隐藏视频播放器
                    showVideoPlayer = false
                    
                    // 立即跳转到主视图
                    print("🔄 Continue button tapped, transitioning to main view")
                    showMainView = true
                }) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.backgroundColor)
                        
                        Image(systemName: "arrow.right")
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
                .padding(.bottom, 40)  // 距离底部40像素
            }
        }
        .onAppear {
            print("🎬 WelcomeView appeared with AVPlayerViewController")
            // 每次视图出现时重新随机选择视频
            selectRandomVideo()
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainTabView()
        }
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