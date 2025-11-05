//
//  MainTabView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AIMusicView()
                .tabItem {
                    Label("AI Music", systemImage: "music.note")
                }
                .tag(0)
            
            CreateView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
                .tag(1)
            
            MyMusicsView()
                .tabItem {
                    Label("My Songs", systemImage: "list.bullet")
                }
                .tag(2)
        }
        .musaiBackground()
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemGreen
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
}