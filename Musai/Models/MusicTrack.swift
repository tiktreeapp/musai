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
    @Attribute(.persisted) var id: UUID
    @Attribute(.persisted) var title: String
    @Attribute(.persisted) var lyrics: String
    @Attribute(.persisted) var style: MusicStyle
    @Attribute(.persisted) var mode: MusicMode
    @Attribute(.persisted) var speed: MusicSpeed
    @Attribute(.persisted) var instrumentation: MusicInstrumentation
    @Attribute(.persisted) var vocal: MusicVocal
    @Attribute(.persisted) var imageData: Data?
    @Attribute(.persisted) var audioURL: String? // 原始URL（可能过期）
    @Attribute(.persisted) var localFilePath: String? // 本地缓存路径
    @Attribute(.persisted) var cloudinaryURL: String? // Cloudinary URL
    @Attribute(.persisted) var createdAt: Date
    @Attribute(.persisted) var duration: TimeInterval?
    @Attribute(.persisted) var isPlaying: Bool = false
    @Attribute(.persisted) var isCachedLocally: Bool = false
    @Attribute(.persisted) var isUploadedToCloud: Bool = false
    @Attribute(.persisted) var uploadDate: Date?
    @Attribute(.persisted) var lastPlayedAt: Date?
    @Attribute(.persisted) var playCount: Int = 0
    
    init(title: String, lyrics: String, style: MusicStyle, mode: MusicMode, speed: MusicSpeed, instrumentation: MusicInstrumentation, vocal: MusicVocal, imageData: Data? = nil, duration: TimeInterval? = nil) {
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
        self.duration = duration
    }
}

enum MusicStyle: String, CaseIterable, Codable {
    case pop = "Pop"
    case rnb = "R&B"
    case edm = "EDM"
    case rock = "Rock"
    case jazz = "Jazz"
    case classical = "Classical"
    case hipHop = "Hip-Hop"
    case indie = "Indie"
    case lofi = "Lo-fi"
    case ambient = "Ambient"
    case folk = "Folk"
    case synthwave = "Synthwave"
    
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
    case romantic = "Romantic"
    case dramatic = "Dramatic"
    case dreamy = "Dreamy"
    
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
    case strings = "Strings"
    case bass = "Bass"
    case vocalLead = "Vocal Lead"
    case drums = "Drums"
    case acousticMix = "Acoustic Mix"
    
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