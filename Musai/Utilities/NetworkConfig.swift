//
//  NetworkConfig.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation

struct NetworkConfig {
    static let shared = NetworkConfig()
    
    // Backend Configuration
    let baseURL = "https://musai-backend.onrender.com/api"
    let serverID = "srv-d42795gdl3ps73ee86ng"
    
    // Replicate API Configuration
    let replicateAPIKey = ProcessInfo.processInfo.environment["REPLICATE_API_KEY"] ?? ""
    let replicateModel = "minimax/music-1.5"
    
    // Cloudinary Configuration
    let cloudinaryCloudName = ProcessInfo.processInfo.environment["CLOUDINARY_CLOUD_NAME"] ?? ""
    let cloudinaryAPIKey = ProcessInfo.processInfo.environment["CLOUDINARY_API_KEY"] ?? ""
    let cloudinaryAPISecret = ProcessInfo.processInfo.environment["CLOUDINARY_API_SECRET"] ?? ""
    let cloudinaryUploadPreset = "musai_unsigned"
    
    // API Endpoints
    struct Endpoints {
        static let generateMusic = "/generate"
        static let uploadImage = "/upload"
        static let getMusicHistory = "/history"
        static let deleteMusic = "/delete"
        static let getUserProfile = "/profile"
    }
    
    // Request Headers
    var defaultHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    // Timeouts
    let requestTimeout: TimeInterval = 30
    let resourceTimeout: TimeInterval = 60
    
    private init() {}
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int)
    case unauthorized
    case forbidden
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        }
    }
}