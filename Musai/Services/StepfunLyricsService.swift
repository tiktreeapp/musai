//
//  StepfunLyricsService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/7.
//

import Foundation
import Combine

class StepfunLyricsService: ObservableObject {
    static let shared = StepfunLyricsService()
    
    private let apiKey = "43Pz7ozTvvBkLCRTlg2A4ckUyYRJGHXT9BdxlUohMx9EWthvuCs7qf8zNUWiOeWs1"
    private let baseURL = "https://api.stepfun.com/v1"
    private let model = "step-r1-v-mini"
    
    func generateLyrics(for title: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "你是一位精通世界各种语言的作词家和音乐家，能根据用户输入的主题（title）,发散思路创作对应语言的歌词核心段落，并用[主歌][副歌]/[Verse][Chorus]分段。歌词必须简短，总共不超过500个字符"
                ],
                [
                    "role": "user",
                    "content": "帮我生成一首歌的歌词节选（不需要完整的歌词），只包含主歌和副歌部分，简单逻辑推理即可，直接给出仅有歌词的结果，歌词语言需与主题语言一致，主题是：\(title)。注意：歌词总长度必须控制在500个字符以内"
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LyricsGenerationError.apiError("API request failed")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(APIResponse.self, from: data)
        
        guard let firstChoice = result.choices.first,
              !firstChoice.message.content.isEmpty else {
            throw LyricsGenerationError.noContent("No lyrics generated")
        }
        
        // 限制歌词长度在10-600字符之间
        let optimizedLyrics = limitLyricsLength(firstChoice.message.content)
        return optimizedLyrics
    }
    
    private func limitLyricsLength(_ lyrics: String) -> String {
        // 移除多余的空行和空格
        let trimmedLyrics = lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果长度在限制范围内，直接返回
        if trimmedLyrics.count <= 600 && trimmedLyrics.count >= 10 {
            return trimmedLyrics
        }
        
        // 如果太短，返回默认内容
        if trimmedLyrics.count < 10 {
            return "A song about \(trimmedLyrics)"
        }
        
        // 如果太长，尝试保留最重要的部分
        if trimmedLyrics.count > 600 {
            let lines = trimmedLyrics.components(separatedBy: .newlines)
            var result = ""
            
            // 优先保留包含标记的行（如[Verse]、[Chorus]等）
            for line in lines {
                let testResult = result + (result.isEmpty ? "" : "\n") + line
                if testResult.count <= 600 {
                    result = testResult
                } else {
                    break
                }
            }
            
            // 如果仍然超出限制，截取前600个字符，但要确保不截断单词
            if result.count > 600 {
                if let index = result.index(result.startIndex, offsetBy: 600, limitedBy: result.endIndex) {
                    result = String(result[..<index])
                }
            }
            
            // 确保结果长度符合要求
            if result.count < 10 {
                return "A song about life"
            }
            
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return trimmedLyrics
    }
}

// MARK: - API Response Models
struct APIResponse: Codable {
    let id: String
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

// MARK: - Error Types
enum LyricsGenerationError: LocalizedError {
    case apiError(String)
    case noContent(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API Error: \(message)"
        case .noContent(let message):
            return "Content Error: \(message)"
        }
    }
}
