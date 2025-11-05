//
//  SimpleTestView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI

struct SimpleTestView: View {
    var body: some View {
        VStack {
            Text("Musai AI Music Generator")
                .font(.title)
                .foregroundColor(.green)
                .padding()
            
            Text("Test View - Basic Functionality")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
        }
        .background(Color.black)
    }
}

#Preview {
    SimpleTestView()
}