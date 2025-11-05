//
//  NetworkDebugger.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import Foundation
import Combine
import SwiftUI

class NetworkDebugger: ObservableObject {
    @Published var isTesting = false
    @Published var testResults: [TestResult] = []
    
    func testBackendConnection() async {
        isTesting = true
        testResults.removeAll()
        
        // Test 1: Basic connectivity
        await testBasicConnectivity()
        
        // Test 2: Replicate API configuration
        await testReplicateAPI()
        
        // Test 3: Cloudinary configuration
        await testCloudinary()
        
        isTesting = false
    }
    
    private func testBasicConnectivity() async {
        let config = NetworkConfig.shared
        guard let url = URL(string: config.baseURL + "/health") else {
            addTestResult(name: "Basic Connectivity", success: false, message: "Invalid URL")
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                addTestResult(
                    name: "Basic Connectivity",
                    success: success,
                    message: "Status Code: \(httpResponse.statusCode)"
                )
            }
        } catch {
            addTestResult(name: "Basic Connectivity", success: false, message: error.localizedDescription)
        }
    }
    
    private func testReplicateAPI() async {
        let config = NetworkConfig.shared
        let testURL = "https://api.replicate.com/v1/models"
        
        guard let url = URL(string: testURL) else {
            addTestResult(name: "Replicate API", success: false, message: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.replicateAPIKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                addTestResult(
                    name: "Replicate API",
                    success: success,
                    message: "Status Code: \(httpResponse.statusCode)"
                )
            }
        } catch {
            addTestResult(name: "Replicate API", success: false, message: error.localizedDescription)
        }
    }
    
    private func testCloudinary() async {
        let config = NetworkConfig.shared
        let testURL = "https://api.cloudinary.com/v1_1/\(config.cloudinaryCloudName)/ping"
        
        guard let url = URL(string: testURL) else {
            addTestResult(name: "Cloudinary", success: false, message: "Invalid URL")
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200
                addTestResult(
                    name: "Cloudinary",
                    success: success,
                    message: "Status Code: \(httpResponse.statusCode)"
                )
            }
        } catch {
            addTestResult(name: "Cloudinary", success: false, message: error.localizedDescription)
        }
    }
    
    private func addTestResult(name: String, success: Bool, message: String) {
        DispatchQueue.main.async {
            self.testResults.append(TestResult(name: name, success: success, message: message))
        }
    }
}

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let success: Bool
    let message: String
}

struct NetworkDebugView: View {
    @StateObject private var debugger = NetworkDebugger()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: {
                    Task {
                        await debugger.testBackendConnection()
                    }
                }) {
                    HStack {
                        if debugger.isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.backgroundColor))
                                .scaleEffect(0.8)
                        }
                        
                        Text(debugger.isTesting ? "Testing..." : "Test Backend Connection")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.backgroundColor)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primaryColor)
                    .cornerRadius(24)
                }
                .disabled(debugger.isTesting)
                
                if !debugger.testResults.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(debugger.testResults) { result in
                            HStack {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.success ? .green : .red)
                                
                                VStack(alignment: .leading) {
                                    Text(result.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.textColor)
                                    
                                    Text(result.message)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.secondaryTextColor)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Theme.cardBackgroundColor)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .musaiBackground()
            .navigationTitle("Network Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    NetworkDebugView()
}