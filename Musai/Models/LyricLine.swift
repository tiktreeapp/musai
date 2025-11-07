//
//  LyricLine.swift
//  Musai
//
//  Created by Sun1 on 2025/11/4.
//

import Foundation

struct LyricLine: Identifiable {
    let id = UUID()
    let time: Double      // 秒
    let text: String
    
    // 保持与现有代码的兼容性
    var timestamp: TimeInterval {
        return time
    }
}