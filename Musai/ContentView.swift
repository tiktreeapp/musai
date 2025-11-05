//
//  ContentView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MusicTrack.self, inMemory: true)
}