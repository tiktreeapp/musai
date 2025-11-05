//
//  CloudinaryService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation
import SwiftUI
import Combine

class CloudinaryService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let config = NetworkConfig.shared
    private let baseURL: String
    
    init() {
        self.baseURL = "https://api.cloudinary.com/v1_1/\(config.cloudinaryCloudName)/image/upload"
    }
    
    func uploadImage(_ image: UIImage) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
        }
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CloudinaryError.imageCompressionFailed
        }
        
        // Create request
        guard let url = URL(string: baseURL) else {
            throw CloudinaryError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // Create boundary for multipart form data
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        var body = Data()
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(config.cloudinaryUploadPreset)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        // Upload with progress tracking
        let (data, response) = try await uploadWithProgress(request: urlRequest, bodySize: body.count)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.serverError
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Cloudinary error: \(errorString)")
            throw CloudinaryError.uploadFailed
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secureURL = json["secure_url"] as? String else {
            throw CloudinaryError.invalidResponse
        }
        
        return secureURL
    }
    
    private func uploadWithProgress(request: URLRequest, bodySize: Int) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.uploadTask(with: request, from: request.httpBody) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data, let response = response else {
                    continuation.resume(throwing: CloudinaryError.uploadFailed)
                    return
                }
                
                continuation.resume(returning: (data, response))
            }
            
            // Progress tracking would require custom implementation using URLSessionTaskDelegate
            // For now, we'll simulate progress
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.uploadProgress = min(self.uploadProgress + 0.1, 0.9)
                if self.uploadProgress >= 0.9 {
                    timer.invalidate()
                }
            }
            
            task.resume()
        }
    }
    
    func deleteImage(publicID: String) async throws {
        // Implement image deletion if needed
        // This would require authentication with API secret
    }
}

// MARK: - Error Types
enum CloudinaryError: LocalizedError {
    case invalidURL
    case imageCompressionFailed
    case uploadFailed
    case serverError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Cloudinary URL"
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload image"
        case .serverError:
            return "Cloudinary server error"
        case .invalidResponse:
            return "Invalid response from Cloudinary"
        }
    }
}