//
//  MusaiApp.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import SwiftData

@main
struct MusaiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MusicTrack.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .preferredColorScheme(.dark)
                .onAppear {
                    print("🚀 Musai App started, showing WelcomeView")
                    // 初始化订阅管理器
                    SubscriptionManager.shared.loadDiamondCount()
                    // 获取订阅产品
                    Task {
                        await SubscriptionManager.shared.fetchProducts()
                        await SubscriptionManager.shared.checkSubscriptionStatus()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
