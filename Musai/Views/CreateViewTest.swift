//
//  CreateViewTest.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI

// Simple test view to verify Create functionality
struct CreateViewTest: View {
    @State private var showingCreateView = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create View Test")
                .font(.title)
                .foregroundColor(Theme.textColor)
            
            Button("Open Create View") {
                showingCreateView = true
            }
            .foregroundColor(Theme.backgroundColor)
            .padding()
            .background(Theme.primaryColor)
            .cornerRadius(10)
        }
        .musaiBackground()
        .sheet(isPresented: $showingCreateView) {
            CreateView()
        }
    }
}

#Preview {
    CreateViewTest()
}