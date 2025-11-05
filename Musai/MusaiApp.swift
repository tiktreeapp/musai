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
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
