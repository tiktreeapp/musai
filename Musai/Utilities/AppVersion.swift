//
//  AppVersion.swift
//  Musai
//
//  Created by Sun1 on 2025/11/10.
//

import Foundation

struct AppVersion {
    /// 从 Bundle 中读取当前版本号
    static var current: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3"
    }
    
    /// 检查是否是新版本（与上次记录的版本比较）
    static var isNewVersion: Bool {
        let currentVersion = current
        let lastVersion = UserDefaults.standard.string(forKey: "LastAppVersion") ?? ""
        return currentVersion != lastVersion
    }
    
    /// 标记当前版本为已查看
    static func markCurrentVersionAsViewed() {
        UserDefaults.standard.set(current, forKey: "LastAppVersion")
    }
}