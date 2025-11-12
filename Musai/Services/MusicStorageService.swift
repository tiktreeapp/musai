//
//  MusicStorageService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/4.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class MusicStorageService: ObservableObject {
    static let shared = MusicStorageService()
    
    // 后端URL配置
    private let backendURL = "https://musai-backend.onrender.com"
    
    // 本地缓存管理
    private let musicCacheDirectory: URL
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var storageStats = StorageInfo(localSize: 0, cloudCount: 0, totalTracks: 0)
    
    struct StorageInfo {
        let localSize: Int64
        let cloudCount: Int
        let totalTracks: Int
    }
    
    private init() {
        // 使用固定的缓存路径，不依赖应用的Documents目录
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        musicCacheDirectory = cachesDirectory.appendingPathComponent("Musai/MusicCache")
        try? FileManager.default.createDirectory(at: musicCacheDirectory, withIntermediateDirectories: true)
        print("📁 Music cache directory: \(musicCacheDirectory.path)")
    }
    
    /// 保存音乐到本地缓存
    func saveMusicLocally(musicURL: URL, musicTrack: MusicTrack) async throws -> URL {
        let trackID = musicTrack.id.uuidString
        
        let localURL = musicCacheDirectory.appendingPathComponent("\(trackID).mp3")
        
        // 下载音乐文件
        let (data, _) = try await URLSession.shared.data(from: musicURL)
        try data.write(to: localURL)
        print("💾 Local cache saved: \(localURL.path)")
        print("📁 File size: \(data.count) bytes")
        
        // 更新数据库中的本地路径
        musicTrack.localFilePath = localURL.path
        musicTrack.isCachedLocally = true
        
        // 保存更改到数据库
        if let modelContext = musicTrack.modelContext {
            try modelContext.save()
            print("✅ Database updated with local path")
        }
        
        return localURL
    }
    
    /// 上传音乐到云端（通过后端）
    func uploadMusicToCloudinary(musicTrack: MusicTrack) async throws -> String {
        guard let localPath = musicTrack.localFilePath,
              let localURL = URL(string: "file://" + localPath) else {
            throw StorageError.invalidTrack
        }
        
        await MainActor.run {
            isUploading = true
            uploadProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isUploading = false
            }
        }
        
        // 使用后端API上传音乐
        let uploadURL = "\(backendURL)/upload/music"
        
        guard let url = URL(string: uploadURL) else {
            throw StorageError.uploadFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 创建multipart表单数据
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"music\"; filename=\"\(musicTrack.title).mp3\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        
        let fileData = try Data(contentsOf: localURL)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200,
           let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let secureURL = responseData["url"] as? String {
            
            // 更新数据库中的云端URL
            musicTrack.cloudinaryURL = secureURL
            musicTrack.isUploadedToCloud = true
            musicTrack.uploadDate = Date()
            
            // 保存到数据库
            if let modelContext = musicTrack.modelContext {
                try modelContext.save()
                print("✅ Database updated with Cloudinary URL")
            }
            
            await MainActor.run {
                uploadProgress = 1.0
            }
            
            print("☁️ Cloudinary upload successful:")
            print("  - URL: \(secureURL)")
            print("  - Track: \(musicTrack.title)")
            print("  - Date: \(Date())")
            return secureURL
        } else {
            throw StorageError.uploadFailed
        }
    }
    
    /// 获取音乐播放URL（优先本地，其次云端）
    func getPlayableURL(for musicTrack: MusicTrack) -> URL? {
        print("\n🎵 Getting playable URL for: \(musicTrack.title)")
        print("  - Local path: \(musicTrack.localFilePath ?? "none")")
        print("  - Cloudinary URL: \(musicTrack.cloudinaryURL ?? "none")")
        print("  - Original URL: \(musicTrack.audioURL ?? "none")")
        
        // 优先使用本地缓存
        if let localPath = musicTrack.localFilePath,
           FileManager.default.fileExists(atPath: localPath) {
            let localURL = URL(fileURLWithPath: localPath)
            print("✅ Using local cached file: \(localURL.lastPathComponent)")
            return localURL
        } else if let localPath = musicTrack.localFilePath {
            print("❌ Local file not found at: \(localPath)")
        }
        
        // 如果本地文件不存在，尝试从云端恢复
        if let cloudinaryURL = musicTrack.cloudinaryURL,
           let cloudURL = URL(string: cloudinaryURL) {
            print("🌐 Attempting to use Cloudinary URL...")
            // 异步恢复本地缓存
            Task {
                do {
                    _ = try await restoreFromCloud(cloudURL: cloudURL, musicTrack: musicTrack)
                    print("✅ Successfully restored local cache from cloud")
                } catch {
                    print("❌ Failed to restore from cloud: \(error)")
                }
            }
            return cloudURL
        }
        
        // 最后尝试原始URL（可能已过期）
        if let originalURL = musicTrack.audioURL,
           let url = URL(string: originalURL) {
            print("⚠️ Using potentially expired original URL")
            return url
        }
        
        print("❌ No playable URL available")
        return nil
    }
    
    /// 从云端恢复本地缓存
    private func restoreFromCloud(cloudURL: URL, musicTrack: MusicTrack) async throws -> URL {
        let trackID = musicTrack.id.uuidString
        let localURL = musicCacheDirectory.appendingPathComponent("\(trackID).mp3")
        
        // 下载音乐文件
        let (data, _) = try await URLSession.shared.data(from: cloudURL)
        try data.write(to: localURL)
        
        // 更新数据库中的本地路径
        musicTrack.localFilePath = localURL.path
        musicTrack.isCachedLocally = true
        
        // 保存到数据库
        if let modelContext = musicTrack.modelContext {
            try modelContext.save()
        }
        
        print("📥 Restored local cache: \(localURL.lastPathComponent)")
        return localURL
    }
    
    /// 清理损坏的缓存文件（保留所有有效文件）
    func cleanupCorruptedCache() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: musicCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            var filesToDelete: [URL] = []
            
            for file in files {
                // 检查文件是否损坏
                if let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
                   fileSize < 1024 { // 小于1KB的文件可能是损坏的
                    filesToDelete.append(file)
                }
            }
            
            // 删除损坏的文件
            for file in filesToDelete {
                try FileManager.default.removeItem(at: file)
                print("🗑️ Removed corrupted cache file: \(file.lastPathComponent)")
            }
            
            await updateStorageStats()
            
        } catch {
            print("❌ Cache cleanup failed: \(error)")
        }
    }
    
    /// 验证所有本地缓存文件的有效性
    func validateCacheFiles() async -> Int {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: musicCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            var validCount = 0
            
            for file in files {
                if let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
                   fileSize >= 1024 { // 大于1KB认为是有效文件
                    validCount += 1
                }
            }
            
            print("📊 Cache validation: \(validCount)/\(files.count) files are valid")
            return validCount
            
        } catch {
            print("❌ Cache validation failed: \(error)")
            return 0
        }
    }
    
    /// 更新存储统计信息
    func updateStorageStats() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: musicCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            let totalSize = files.compactMap { url in
                (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            }.reduce(0, +)
            
            // 这里需要从数据库获取云端统计
            let cloudCount = 0 // TODO: 从数据库查询
            
            storageStats = StorageInfo(
                localSize: Int64(totalSize),
                cloudCount: cloudCount,
                totalTracks: cloudCount + files.count
            )
            
        } catch {
            print("❌ Failed to update storage stats: \(error)")
        }
    }
    
    /// 检查存储空间并提示用户
    func checkStorageSpace() -> StorageStatus {
        let totalSpace = getLocalCacheSize()
        let freeSpace = getFreeDiskSpace()
        
        if totalSpace > 500 * 1024 * 1024 { // 500MB
            return .needsCleanup
        } else if freeSpace < 100 * 1024 * 1024 { // 100MB
            return .diskSpaceLow
        } else {
            return .normal
        }
    }
    
    private func getLocalCacheSize() -> Int64 {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: musicCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            return Int64(files.compactMap { url in
                (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            }.reduce(0, +))
        } catch {
            return 0
        }
    }
    
    private func getFreeDiskSpace() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: musicCacheDirectory.path)
            return (attributes[.systemFreeSize] as? Int64) ?? 0
        } catch {
            return 0
        }
    }
}

enum StorageError: LocalizedError {
    case invalidTrack
    case downloadFailed
    case uploadFailed
    case insufficientSpace
    
    var errorDescription: String? {
        switch self {
        case .invalidTrack:
            return "Invalid music track"
        case .downloadFailed:
            return "Failed to download music"
        case .uploadFailed:
            return "Failed to upload music"
        case .insufficientSpace:
            return "Insufficient storage space"
        }
    }
}

enum StorageStatus {
    case normal
    case needsCleanup
    case diskSpaceLow
}