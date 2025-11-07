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
    
    // Cloudinary配置
    private let cloudinaryCloudName = "dygx9d3gi"
    private let cloudinaryAPIKey = "771822174588294"
    private let cloudinaryAPISecret = "r_eWr4nK5jdpK5yWRNVkL7i6wY4"
    private let uploadPreset = "musai_unsigned"
    
    // 本地缓存管理
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        // 创建本地缓存目录
        musicCacheDirectory = documentsDirectory.appendingPathComponent("MusicCache")
        try? FileManager.default.createDirectory(at: musicCacheDirectory, withIntermediateDirectories: true)
    }
    
    /// 保存音乐到本地缓存
    func saveMusicLocally(musicURL: URL, musicTrack: MusicTrack) async throws -> URL {
        let trackID = musicTrack.id.uuidString
        
        let localURL = musicCacheDirectory.appendingPathComponent("\(trackID).mp3")
        
        // 下载音乐文件
        let (data, _) = try await URLSession.shared.data(from: musicURL)
        try data.write(to: localURL)
        
        // 更新数据库中的本地路径
        musicTrack.localFilePath = localURL.path
        musicTrack.isCachedLocally = true
        
        return localURL
    }
    
    /// 上传音乐到Cloudinary（后台任务）
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
        
        // 使用原生API上传到Cloudinary
        let cloudinaryURL = "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/video/upload"
        
        guard let url = URL(string: cloudinaryURL) else {
            throw StorageError.uploadFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 创建multipart表单数据
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // 添加文件夹
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("musai_tracks/\(musicTrack.id.uuidString)\r\n".data(using: .utf8)!)
        
        // 添加文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(musicTrack.title).mp3\"\r\n".data(using: .utf8)!)
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
           let secureURL = responseData["secure_url"] as? String {
            
            // 更新数据库中的云端URL
            musicTrack.cloudinaryURL = secureURL
            musicTrack.isUploadedToCloud = true
            musicTrack.uploadDate = Date()
            
            await MainActor.run {
                uploadProgress = 1.0
            }
            
            print("✅ Upload successful: \(secureURL)")
            return secureURL
        } else {
            throw StorageError.uploadFailed
        }
    }
    
    /// 获取音乐播放URL（优先本地，其次云端）
    func getPlayableURL(for musicTrack: MusicTrack) -> URL? {
        // 优先使用本地缓存
        if let localPath = musicTrack.localFilePath,
           let localURL = URL(string: "file://" + localPath),
           FileManager.default.fileExists(atPath: localPath) {
            return localURL
        }
        
        // 使用云端URL
        if let cloudinaryURL = musicTrack.cloudinaryURL {
            return URL(string: cloudinaryURL)
        }
        
        // 使用原始URL（可能已过期）
        if let originalURL = musicTrack.audioURL,
           let url = URL(string: originalURL) {
            return url
        }
        
        return nil
    }
    
    /// 清理本地缓存（保留最近播放的）
    func cleanupLocalCache(keepRecent count: Int = 20) async {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: musicCacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            // 按创建时间排序，删除旧的文件
            let sortedFiles = files.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // 保留最近的count个文件
            let filesToDelete = Array(sortedFiles.dropFirst(count))
            
            for file in filesToDelete {
                try FileManager.default.removeItem(at: file)
            }
            
            await updateStorageStats()
            
        } catch {
            print("❌ Cache cleanup failed: \(error)")
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