//
//  MusicTrack.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation
import SwiftData

@Model
final class MusicTrack {
    var id: UUID
    var title: String
    var lyrics: String
    var style: MusicStyle
    var mode: MusicMode
    var speed: MusicSpeed
    var instrumentation: MusicInstrumentation
    var vocal: MusicVocal
    var imageData: Data?
    var audioURL: String? // 原始URL（可能过期）
    var localFilePath: String? // 本地缓存路径
    var cloudinaryURL: String? // Cloudinary URL
    var createdAt: Date
    var duration: TimeInterval?
    var isPlaying: Bool = false
    var isCachedLocally: Bool = false
    var isUploadedToCloud: Bool = false
    var uploadDate: Date?
    var lastPlayedAt: Date?
    var playCount: Int = 0
    
    init(title: String, lyrics: String, style: MusicStyle, mode: MusicMode, speed: MusicSpeed, instrumentation: MusicInstrumentation, vocal: MusicVocal, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.lyrics = lyrics
        self.style = style
        self.mode = mode
        self.speed = speed
        self.instrumentation = instrumentation
        self.vocal = vocal
        self.imageData = imageData
        self.createdAt = Date()
    }
}

enum MusicStyle: String, CaseIterable, Codable {
    case pop = "Pop"
    case rnb = "R&B"
    case edm = "EDM"
    case rock = "Rock"
    case jazz = "Jazz"
    case classical = "Classical"
    
    var displayName: String {
        return self.rawValue
    }
}

enum MusicMode: String, CaseIterable, Codable {
    case joyful = "Joyful"
    case melancholic = "Melancholic"
    case motivational = "Motivational"
    case reflective = "Reflective"
    case chill = "Chill"
    
    var displayName: String {
        return self.rawValue
    }
}

enum MusicSpeed: String, CaseIterable, Codable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"
    
    var displayName: String {
        return self.rawValue
    }
}

enum MusicInstrumentation: String, CaseIterable, Codable {
    case piano = "Piano"
    case guitar = "Guitar"
    case synth = "Synth"
    case orchestral = "Orchestral"
    case percussion = "Percussion"
    
    var displayName: String {
        return self.rawValue
    }
}

enum MusicVocal: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
    case noLimit = "No Limit"
    
    var displayName: String {
        return self.rawValue
    }
}