//
//  LegacyMusicCacheService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/4.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class LegacyMusicCacheService: ObservableObject {
    static let shared = LegacyMusicCacheService()
    
    @Published var isCaching = false
    @Published var cacheProgress: Double = 0.0
    @Published var cachedCount: Int = 0
    @Published var totalCount: Int = 0
    
    private init() {}
    
    /// 批量缓存现有歌曲到本地
    func cacheExistingTracks(modelContext: ModelContext) async {
        isCaching = true
        cacheProgress = 0.0
        cachedCount = 0
        
        do {
            // 获取所有音乐记录
            let descriptor = FetchDescriptor<MusicTrack>()
            let tracks = try modelContext.fetch(descriptor)
            totalCount = tracks.count
            
            print("🎵 Found \(totalCount) tracks to cache")
            
            let storageService = MusicStorageService.shared
            
            for (index, track) in tracks.enumerated() {
                // 跳过已经缓存的
                if track.isCachedLocally {
                    cachedCount += 1
                    cacheProgress = Double(index + 1) / Double(totalCount)
                    continue
                }
                
                // 跳过没有音频URL的
                guard let audioURLString = track.audioURL,
                      let audioURL = URL(string: audioURLString) else {
                    print("⚠️ Skipping track without audio URL: \(track.title)")
                    cacheProgress = Double(index + 1) / Double(totalCount)
                    continue
                }
                
                do {
                    print("📥 Caching track \(index + 1)/\(totalCount): \(track.title)")
                    
                    // 缓存到本地
                    _ = try await storageService.saveMusicLocally(musicURL: audioURL, musicTrack: track)
                    
                    cachedCount += 1
                    cacheProgress = Double(index + 1) / Double(totalCount)
                    
                    // 短暂延迟，避免过快请求
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                    
                } catch {
                    print("❌ Failed to cache \(track.title): \(error.localizedDescription)")
                }
            }
            
            print("✅ Cache completed: \(cachedCount)/\(totalCount) tracks cached")
            
        } catch {
            print("❌ Failed to fetch tracks: \(error)")
        }
        
        isCaching = false
    }
    
    /// 检查缓存状态
    func checkCacheStatus(modelContext: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<MusicTrack>()
            let tracks = try modelContext.fetch(descriptor)
            
            totalCount = tracks.count
            cachedCount = tracks.filter { $0.isCachedLocally }.count
            
            print("📊 Cache status: \(cachedCount)/\(totalCount) tracks cached locally")
            
        } catch {
            print("❌ Failed to check cache status: \(error)")
        }
    }
}