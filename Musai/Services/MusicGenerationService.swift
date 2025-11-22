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
    
    init() {
        print("🎵 MusicGenerationService initialized!")
        NSLog("MusicGenerationService initialized!")
        
        // Test backend health on initialization
        Task {
            await testBackendHealth()
        }
    }
    
    private func testBackendHealth() async {
        do {
            let url = URL(string: "\(backendURL)/health")
            let (_, response) = try await URLSession.shared.data(from: url!)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 Backend health check status: \(httpResponse.statusCode)")
            }
        } catch {
            print("🔍 Backend health check failed: \(error)")
        }
    }
    
    // MARK: - Backend Wake-up Methods
    func wakeUpBackendIfNeeded() async {
        print("🔍 Checking if backend needs to be woken up...")
        
        // Try to ping the backend health endpoint
        let url = URL(string: "\(backendURL)/health")
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url!)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Backend is already awake (status: \(httpResponse.statusCode))")
                    return
                } else {
                    print("⚠️ Backend responded with status: \(httpResponse.statusCode), attempting to wake up...")
                }
            }
        } catch {
            print("⚠️ Backend is not responding, attempting to wake up...")
        }
        
        // If we reach here, the backend may be sleeping, so we'll try to wake it up
        await attemptToWakeUpBackend()
    }
    
    private func attemptToWakeUpBackend() async {
        print("🚀 Attempting to wake up backend service...")
        
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                let request = URLRequest(url: URL(string: "\(backendURL)/health")!)
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("✅ Backend successfully woken up!")
                    return
                }
            } catch {
                print("⚠️ Attempt \(retryCount + 1) failed: \(error)")
            }
            
            retryCount += 1
            print("⏳ Waiting before retry \(retryCount)/\(maxRetries)...")
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds before retry
        }
        
        print("❌ Failed to wake up backend after \(maxRetries) attempts")
    }
    
    private func logDebug(_ message: String) {
        print("🔍 MusicGeneration: \(message)")
        NSLog("MusicGeneration: \(message)")
    }
    
    // MARK: - Properties
    private let backendURL = "https://musai-backend.onrender.com"
    
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
        
        let timestamp = DateFormatter().string(from: Date())
        print("=== [\(timestamp)] MUSIC GENERATION START ===")
        NSLog("=== MUSIC GENERATION START ===")
        logDebug("Starting music generation")
        print("🎵 Lyrics: \(prompt)")
        print("🎵 Lyrics length: \(prompt.count) characters")
        logDebug("Parameters: style=\(style.rawValue), mode=\(mode.rawValue), speed=\(speed.rawValue)")
        logDebug("Instrumentation: \(instrumentation.rawValue), Vocal: \(vocal.rawValue)")
        logDebug("Has image: \(imageData != nil)")
        if imageData != nil {
            print("📷 Image size: \(imageData!.count) bytes")
        }
        
        // Wake up backend service before starting music generation
        print("🔍 Checking backend status before music generation...")
        await wakeUpBackendIfNeeded()
        
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        // Construct the request body for backend API (Node.js SDK format)
        let requestBody: [String: Any] = [
            "lyrics": prompt,  // Node.js SDK expects lyrics field
            "prompt": "\(style.rawValue), \(mode.rawValue), \(speed.rawValue), \(instrumentation.rawValue), \(vocal.rawValue)",  // Combined style parameters
            "bitrate": 256000,
            "sample_rate": 44100,
            "audio_format": "mp3"
        ]
        
        // Image is only stored locally, not uploaded to backend
        logDebug("Image will be stored locally only, not uploaded")
        
        // Create the request without image
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            logDebug("Failed to serialize request body")
            throw MusicGenerationError.invalidRequest
        }
        
        // Log the request body for debugging
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            logDebug("Request body: \(jsonString)")
        }
        
        // Create the URL request for backend API
            let generateURL = "\(backendURL)/generate"
            logDebug("Creating request to URL: \(generateURL)")
            guard let url = URL(string: generateURL) else {
                logDebug("Failed to create backend URL")
                throw MusicGenerationError.invalidURL
            }
            
            // Log the JSON that will be sent
            if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                logDebug("Request JSON that will be sent:")
                logDebug(jsonString)
                print("📤 Request JSON: \(jsonString)")
            }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 120  // Set timeout to 120 seconds
        
        logDebug("Sending request to backend without image")
        
        // Send the request with retry for 503 errors (backend hibernation)
        var retryCount = 0
        let maxRetries = 3
        var data: Data
        var response: URLResponse
        
        while true {
            do {
                (data, response) = try await URLSession.shared.data(for: request)
                
                // Check if we got a 503 response and should retry
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 503,
                   retryCount < maxRetries {
                    retryCount += 1
                    logDebug("Backend is hibernating (503), retrying... Attempt \(retryCount)/\(maxRetries)")
                    // Wait 10 seconds before retry
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    continue
                }
                break
            } catch {
                // For network errors, also retry
                if retryCount < maxRetries {
                    retryCount += 1
                    logDebug("Network error, retrying... Attempt \(retryCount)/\(maxRetries)")
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    continue
                }
                throw error
            }
        }
        
        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicGenerationError.invalidResponse
        }
        
        logDebug("Backend response status: \(httpResponse.statusCode)")
        
        // Log response body for debugging BEFORE checking status code
        print("=== BACKEND RESPONSE DEBUG ===")
        print("Status code: \(httpResponse.statusCode)")
        print("Raw response data size: \(data.count) bytes")
        
        if data.count > 0 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body (UTF-8): \(responseString)")
                logDebug("Backend response body: \(responseString)")
            } else {
                print("Response body is not valid UTF-8")
                // Try to print first 100 bytes as hex
                let bytesToPrint = min(100, data.count)
                let hexString = data.prefix(bytesToPrint).map { String(format: "%02x", $0) }.joined()
                print("Response hex (first \(bytesToPrint) bytes): \(hexString)")
            }
        } else {
            print("Response body is empty!")
        }
        print("=== END DEBUG ===")
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200, 201:
            // Success, continue processing
            logDebug("Backend request successful")
            
            // Decode the response
            do {
                let backendResponse = try JSONDecoder().decode(BackendResponse.self, from: data)
                logDebug("Received prediction ID: \(backendResponse.predictionId)")
                
                // Return the prediction ID
                return backendResponse.predictionId
            } catch {
                logDebug("Failed to decode backend response as BackendResponse: \(error)")
                
                // Try to decode as generic error response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    logDebug("Error response details: \(errorDict)")
                    print("🔍 Error response details: \(errorDict)")
                }
                
                throw MusicGenerationError.invalidResponse
            }
        case 400:
            logDebug("Backend error: Bad request (400)")
            // Also log error response details for 400
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                logDebug("Error response details: \(errorDict)")
                print("🔍 400 Error response details: \(errorDict)")
            }
            throw MusicGenerationError.invalidRequest
        case 401:
            logDebug("Backend error: Unauthorized (401)")
            throw MusicGenerationError.invalidAPIKey
        case 429:
            logDebug("Backend error: Rate limit exceeded (429)")
            throw MusicGenerationError.rateLimitExceeded
        case 500...599:
            logDebug("Backend error: Server error (\(httpResponse.statusCode))")
            throw MusicGenerationError.serverError(httpResponse.statusCode)
        default:
            logDebug("Backend error: Unknown status code (\(httpResponse.statusCode))")
            throw MusicGenerationError.invalidResponse
        }
        
        
    }
    
    func getMusicURL(for predictionId: String) async throws -> URL {
        let pollStartTime = Date()
        let timestamp = DateFormatter().string(from: pollStartTime)
        print("=== [\(timestamp)] MUSIC URL POLLING START ===")
        print("🔍 Checking status for prediction ID: \(predictionId)")
        NSLog("=== MUSIC URL POLLING START - ID: \(predictionId) ===")
        
        // Create the URL for checking the prediction status via backend API
        guard let url = URL(string: "\(backendURL)/status/\(predictionId)") else {
            print("❌ Failed to create status URL for ID: \(predictionId)")
            throw MusicGenerationError.invalidURL
        }
        
        print("📡 Status URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // Set timeout for status check
        
        // Poll the API until the prediction is complete
        var pollCount = 0
        let maxPolls = 90  // Maximum 90 polls (3 minutes)
        print("⏳ Starting polling (max \(maxPolls) attempts, 2 seconds interval)...")
        
        while pollCount < maxPolls {
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
            let backendResponse = try JSONDecoder().decode(BackendStatusResponse.self, from: data)
            
            // Check if the prediction is complete
            if backendResponse.status == "succeeded" {
                let pollEndTime = Date()
                let totalPollTime = pollEndTime.timeIntervalSince(pollStartTime)
                print("✅ [\(DateFormatter().string(from: pollEndTime))] Music generation succeeded!")
                print("⏱️ Total polling time: \(String(format: "%.2f", totalPollTime)) seconds")
                print("📊 Total polls: \(pollCount)")
                NSLog("✅ MUSIC GENERATION SUCCEEDED - ID: \(predictionId), Polls: \(pollCount), Time: \(String(format: "%.2f", totalPollTime))s")
                
                if let urlString = backendResponse.musicURL {
                    print("🎵 Music URL from backend: \(urlString)")
                    // If URL is relative, prepend backend URL
                    let fullURLString = urlString.hasPrefix("http") ? urlString : "\(backendURL)\(urlString)"
                    print("🎵 Full music URL: \(fullURLString)")
                    if let musicURL = URL(string: fullURLString) {
                        // 音乐生成成功，请求评价
                        Task { @MainActor in
                            ReviewPromptService.shared.checkAndRequestReview()
                        }
                        return musicURL
                    } else {
                        print("❌ Music generation succeeded but invalid musicURL: \(fullURLString)")
                        NSLog("❌ INVALID MUSIC URL: \(fullURLString)")
                        throw MusicGenerationError.invalidMusicURL
                    }
                } else {
                    print("❌ Music generation succeeded but no musicURL returned")
                    NSLog("❌ NO MUSIC URL RETURNED - ID: \(predictionId)")
                    throw MusicGenerationError.invalidMusicURL
                }
            } else if backendResponse.status == "failed" {
                let pollEndTime = Date()
                let totalPollTime = pollEndTime.timeIntervalSince(pollStartTime)
                print("❌ [\(DateFormatter().string(from: pollEndTime))] Music generation failed!")
                print("⏱️ Total polling time: \(String(format: "%.2f", totalPollTime)) seconds")
                print("📊 Total polls: \(pollCount)")
                
                // Throw an error if the prediction failed
                let errorMessage = backendResponse.error ?? "Unknown error"
                print("🚫 Failure reason: \(errorMessage)")
                NSLog("❌ MUSIC GENERATION FAILED - ID: \(predictionId), Error: \(errorMessage), Polls: \(pollCount)")
                throw MusicGenerationError.predictionFailed(errorMessage)
            } else {
                // Log the current status every 10 seconds (reduce noise)
                if pollCount % 5 == 0 {
                    let elapsed = Date().timeIntervalSince(pollStartTime)
                    print("⏳ [\(DateFormatter().string(from: Date()))] Music generation status: \(backendResponse.status)")
                    print("   Poll #\(pollCount), elapsed: \(String(format: "%.1f", elapsed))s")
                }
                generationProgress = min(0.9, generationProgress + 0.1)
                pollCount += 1
                // Wait for 2 seconds before polling again
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        // If we reach here, we've exceeded the maximum number of polls
        let pollEndTime = Date()
        let totalPollTime = pollEndTime.timeIntervalSince(pollStartTime)
        print("❌ [\(DateFormatter().string(from: pollEndTime))] Music generation timed out!")
        print("⏱️ Total polling time: \(String(format: "%.2f", totalPollTime)) seconds")
        print("📊 Total polls: \(pollCount)/\(maxPolls)")
        NSLog("❌ MUSIC GENERATION TIMEOUT - ID: \(predictionId), Polls: \(pollCount)/\(maxPolls), Time: \(String(format: "%.2f", totalPollTime))s")
        throw MusicGenerationError.predictionFailed("Music generation timed out after \(maxPolls) attempts (\(String(format: "%.2f", totalPollTime))s)")
    }
    
    // MARK: - Image upload is no longer needed for music generation
// Images are stored locally only
/*
private func uploadImageToBackend(imageData: Data) async throws -> String {
    // This method is no longer used - images are stored locally only
}
*/
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