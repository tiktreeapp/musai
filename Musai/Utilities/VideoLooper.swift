//
//  VideoLooper.swift
//  Musai
//
//  Created by Sun1 on 2025/11/8.
//

import AVFoundation
import AVKit
import UIKit

class VideoLooper {
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    
    init(fileName: String, fileType: String) {
        setupPlayer(fileName: fileName, fileType: fileType)
    }
    
    private func setupPlayer(fileName: String, fileType: String) {
        var videoURL: URL?
        
        // 首先尝试在Bundle中查找
        if let path = Bundle.main.path(forResource: fileName, ofType: fileType) {
            videoURL = URL(fileURLWithPath: path)
            print("✅ Found video file in bundle at path: \(path)")
        } else {
            // 尝试查找所有可能的视频文件
            print("🔍 Looking for video files in bundle...")
            let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "mp4", subdirectory: nil) ?? []
            for url in resourceURLs {
                print("📄 Found MP4 resource: \(url.lastPathComponent)")
                if url.lastPathComponent.contains(fileName) {
                    videoURL = url
                    print("✅ Using video file: \(url.path)")
                    break
                }
            }
            
            if videoURL == nil {
                // 尝试查找Videos子目录中的文件
                print("🔍 Looking for video files in Videos subdirectory...")
                let videosURLs = Bundle.main.urls(forResourcesWithExtension: "mp4", subdirectory: "Videos") ?? []
                for url in videosURLs {
                    print("📄 Found MP4 resource in Videos: \(url.lastPathComponent)")
                    if url.lastPathComponent.contains(fileName) {
                        videoURL = url
                        print("✅ Using video file from Videos: \(url.path)")
                        break
                    }
                }
            }
        }
        
        // 如果在bundle中找不到，尝试从应用包外部复制到Documents目录
        if videoURL == nil {
            print("⚠️ Video not found in bundle, attempting to copy from project directory")
            
            // 尝试从应用的bundle外部复制视频
            let projectVideoPath = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("Musai/Videos/\(fileName).\(fileType)")
            print("🔍 Looking for video at project path: \(projectVideoPath.path)")
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationPath = documentsPath.appendingPathComponent("\(fileName).\(fileType)")
            
            if FileManager.default.fileExists(atPath: projectVideoPath.path) {
                // 复制视频文件到Documents目录
                do {
                    if FileManager.default.fileExists(atPath: destinationPath.path) {
                        try FileManager.default.removeItem(at: destinationPath)
                    }
                    try FileManager.default.copyItem(at: projectVideoPath, to: destinationPath)
                    videoURL = destinationPath
                    print("✅ Video copied to documents: \(destinationPath.path)")
                } catch {
                    print("❌ Failed to copy video to documents: \(error)")
                }
            } else {
                print("❌ Video file not found at project path: \(projectVideoPath.path)")
            }
        }
        
        guard let url = videoURL else {
            print("❌ Could not find video file after all attempts")
            print("📁 Bundle resource path: \(Bundle.main.resourcePath ?? "nil")")
            // 列出bundle中的所有文件
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("📂 Files in bundle: \(contents.filter { $0.hasSuffix(".mp4") || $0.hasSuffix(".mov") || $0.hasSuffix(".m4v") })")
                } catch {
                    print("❌ Error listing bundle contents: \(error)")
                }
            }
            return
        }
        
        print("🎬 Loading video from URL: \(url)")
        
        let videoAsset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: videoAsset)
        player = AVQueuePlayer(playerItem: playerItem)
        player?.isMuted = true
        player?.actionAtItemEnd = .none
        
        // 检查视频资产是否有效
        videoAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            DispatchQueue.main.async {
                var error: NSError?
                let status = videoAsset.statusOfValue(forKey: "tracks", error: &error)
                
                switch status {
                case .loaded:
                    print("✅ Video asset loaded successfully")
                case .failed:
                    print("❌ Video asset failed to load: \(error?.localizedDescription ?? "Unknown error")")
                case .cancelled:
                    print("⚠️ Video asset loading cancelled")
                default:
                    print("⚠️ Video asset loading status: \(status)")
                }
            }
        }
        
        // 简化循环播放逻辑 - 只使用 AVPlayerLooper
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        print("✅ Video player setup complete with AVPlayerLooper")
    }
    
    func getPlayer() -> AVQueuePlayer? {
        return player
    }
    
    func play() {
        print("🎬 Playing video")
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    deinit {
        // 移除通知观察器的清理代码（因为没有使用）
        player?.pause()
        player = nil
    }
}