//
//  Theme.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI

struct Theme {
    static let backgroundColor = Color.black
    static let primaryColor = Color.green
    static let secondaryColor = Color.green.opacity(0.8)
    static let tertiaryColor = Color.blue
    static let accentColor = Color.green.opacity(0.6)
    static let textColor = Color.white
    static let secondaryTextColor = Color.gray
    static let cardBackgroundColor = Color.gray.opacity(0.2)
    static let overlayColor = Color.black.opacity(0.7)
}

extension View {
    func musaiBackground() -> some View {
        self.background(Theme.backgroundColor)
    }
    
    func musaiCardStyle() -> some View {
        self.background(Theme.cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.primaryColor, lineWidth: 1)
            )
    }
}