//
//  MusicGenerationService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation
import Combine
import SwiftData

// MARK: - API Response Models
struct ReplicateResponse: Codable {
    let id: String
    let status: String
    let error: String?
    let output: OutputValue?

    enum OutputValue: Codable {
        case string(String)
        case array([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else if let arr = try? container.decode([String].self) {
                self = .array(arr)
            } else {
                throw DecodingError.typeMismatch(OutputValue.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
            }
        }
    }

    var musicURL: String? {
        switch output {
        case .string(let s): return s
        case .array(let a): return a.first
        default: return nil
        }
    }
}

struct BackendResponse: Codable {
    let predictionId: String
    let status: String
    let message: String?
}

struct BackendStatusResponse: Codable {
    let status: String
    let musicURL: String?
    let error: String?
}

struct CloudinaryResponse: Codable {
    let public_id: String
    let secure_url: String
    let format: String
}

// MARK: - MusicGenerationService
@MainActor
final class MusicGenerationService: ObservableObject {
    static let shared = MusicGenerationService()
    
    init() {}
    
    // MARK: - Properties
    private let backendURL = "https://musai-backend.onrender.com"
    private let replicateAPIKey = ProcessInfo.processInfo.environment["REPLICATE_API_KEY"] ?? ""
    private let cloudinaryCloudName = ProcessInfo.processInfo.environment["CLOUDINARY_CLOUD_NAME"] ?? ""
    private let cloudinaryAPIKey = ProcessInfo.processInfo.environment["CLOUDINARY_API_KEY"] ?? ""
    private let cloudinaryAPISecret = ProcessInfo.processInfo.environment["CLOUDINARY_API_SECRET"] ?? ""
    private let cloudinaryUploadPreset = "musai_unsigned"
    
    // MARK: - ObservableObject
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // MARK: - Methods
    func generateMusic(
        prompt: String,
        style: MusicStyle,
        mode: MusicMode,
        speed: MusicSpeed,
        instrumentation: MusicInstrumentation,
        vocal: MusicVocal,
        imageData: Data? = nil
    ) async throws -> String {
        
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        // Construct the request body for Replicate API
        let requestBody: [String: Any] = [
            "version": "5080f14bbbfd3da1cf1387fa8799ce3c24ae7c9f43c2b9f406657d2e70784446",
            "input": [
                "lyrics": prompt,
                "prompt": "\(style.rawValue), \(mode.rawValue), \(instrumentation.rawValue)",
                "bitrate": 256000,
                "sample_rate": 44100,
                "audio_format": "mp3"
            ]
        ]
        
        // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw MusicGenerationError.invalidRequest
        }
        
        // Create the URL request for Replicate API
        guard let url = URL(string: "https://api.replicate.com/v1/predictions") else {
            throw MusicGenerationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(replicateAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicGenerationError.invalidResponse
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200, 201:
            // Success, continue processing
            break
        case 400:
            throw MusicGenerationError.invalidRequest
        case 401:
            throw MusicGenerationError.invalidAPIKey
        case 429:
            throw MusicGenerationError.rateLimitExceeded
        case 500...599:
            throw MusicGenerationError.serverError(httpResponse.statusCode)
        default:
            throw MusicGenerationError.invalidResponse
        }
        
        // Decode the response
        let replicateResponse = try JSONDecoder().decode(ReplicateResponse.self, from: data)
        
        // Return the prediction ID
        return replicateResponse.id
    }
    
    func getMusicURL(for predictionId: String) async throws -> URL {
        // Create the URL for checking the prediction status via Replicate API
        guard let url = URL(string: "https://api.replicate.com/v1/predictions/\(predictionId)") else {
            throw MusicGenerationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(replicateAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Poll the API until the prediction is complete
        while true {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check the response status code
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MusicGenerationError.invalidResponse
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success, continue processing
                break
            case 400:
                throw MusicGenerationError.invalidRequest
            case 401:
                throw MusicGenerationError.invalidAPIKey
            case 429:
                throw MusicGenerationError.rateLimitExceeded
            case 500...599:
                throw MusicGenerationError.serverError(httpResponse.statusCode)
            default:
                throw MusicGenerationError.invalidResponse
            }
            
            // Decode the response
            let replicateResponse = try JSONDecoder().decode(ReplicateResponse.self, from: data)
            
            // Check if the prediction is complete
            if replicateResponse.status == "succeeded", let urlString = replicateResponse.musicURL {
                // Return the URL of the generated music
                guard let musicURL = URL(string: urlString) else {
                    throw MusicGenerationError.invalidMusicURL
                }
                
                return musicURL
            } else if replicateResponse.status == "failed" {
                // Throw an error if the prediction failed
                let errorMessage = replicateResponse.error ?? "Unknown error"
                throw MusicGenerationError.predictionFailed(errorMessage)
            } else {
                // Log the current status and wait before polling again
                print("⏳ Music generation status: \(replicateResponse.status)")
                generationProgress = min(0.9, generationProgress + 0.1)
                // Wait for 2 seconds before polling again
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    private func uploadImageToCloudinary(imageData: Data) async throws -> String {
        // Create the URL for Cloudinary upload
        guard let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload") else {
            throw MusicGenerationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cloudinaryUploadPreset)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Send the request with timeout
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicGenerationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw MusicGenerationError.serverError(httpResponse.statusCode)
        }
        
        // Decode the response
        let cloudinaryResponse = try JSONDecoder().decode(CloudinaryResponse.self, from: data)
        return cloudinaryResponse.secure_url
    }
}

// MARK: - Error Types
enum MusicGenerationError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(Int)
    case invalidMusicURL
    case predictionFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response"
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError(let code):
            return "Server error (status code: \(code))"
        case .invalidMusicURL:
            return "Invalid music URL"
        case .predictionFailed(let errorMessage):
            return "Prediction failed: \(errorMessage)"
        case .networkError:
            return "Network connection error"
        }
    }
}