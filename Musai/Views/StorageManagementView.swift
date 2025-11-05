//
//  StorageManagementView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/4.
//

import SwiftUI
import SwiftData

struct StorageManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storageService = MusicStorageService.shared
    @State private var showingCleanupAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Pull Bar
                HStack {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Theme.secondaryTextColor.opacity(0.5))
                        .frame(width: 36, height: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Storage Status
                VStack(spacing: 16) {
                    Text("Storage Status")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textColor)
                    
                    VStack(spacing: 12) {
                        StorageStatusCard(
                            title: "Local Cache",
                            usedSpace: formatBytes(storageService.storageStats.localSize),
                            icon: "iphone",
                            color: Theme.primaryColor
                        )
                        
                        StorageStatusCard(
                            title: "Cloud Storage",
                            usedSpace: "\(storageService.storageStats.cloudCount) tracks",
                            icon: "icloud",
                            color: Theme.secondaryColor
                        )
                        
                        StorageStatusCard(
                            title: "Total Tracks",
                            usedSpace: "\(storageService.storageStats.totalTracks)",
                            icon: "music.note",
                            color: Theme.textColor
                        )
                    }
                }
                
                // Storage Options
                VStack(spacing: 16) {
                    Text("Management Options")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.textColor)
                    
                    VStack(spacing: 12) {
                        ManagementOptionButton(
                            title: "Cleanup Local Cache",
                            description: "Remove old cached tracks to free up space",
                            icon: "trash",
                            action: {
                                showingCleanupAlert = true
                            }
                        )
                        
                        
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .musaiBackground()
            .navigationTitle("Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryColor)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Cleanup Cache", isPresented: $showingCleanupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Cleanup", role: .destructive) {
                Task {
                    await storageService.cleanupLocalCache()
                }
            }
        } message: {
            Text("This will remove old cached tracks except the 20 most recently played ones. Continue?")
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    
}

struct StorageStatusCard: View {
    let title: String
    let usedSpace: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textColor)
                
                Text(usedSpace)
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

struct ManagementOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primaryColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textColor)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryTextColor)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryTextColor)
            }
            .padding()
            .background(Theme.cardBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StorageManagementView()
}