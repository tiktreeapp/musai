//
//  CustomSlider.swift
//  Musai
//
//  Created by Sun1 on 2025/11/11.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    @State private var isDragging = false
    @State private var sliderWidth: CGFloat = 0
    
    private var progress: Double {
        let min = range.lowerBound
        let max = range.upperBound
        return max > min ? (value - min) / (max - min) : 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress track
                Rectangle()
                    .fill(Theme.primaryColor)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .cornerRadius(2)
                
                // Thumb (reduced to 40% of original size)
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)  // 原始约30px，现在减少到40%
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .offset(x: geometry.size.width * progress - 6)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
            }
            .onAppear {
                sliderWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                sliderWidth = newWidth
            }
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { dragValue in
                    isDragging = true
                    updateValue(at: dragValue.location.x, in: sliderWidth)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
    
    private func updateValue(at location: CGFloat, in width: CGFloat) {
        guard width > 0 else { return }
        let clampedLocation = max(0, min(width, location))
        let percentage = clampedLocation / width
        let rangeSize = range.upperBound - range.lowerBound
        let steppedValue = round((range.lowerBound + percentage * rangeSize) / step) * step
        value = max(range.lowerBound, min(range.upperBound, steppedValue))
    }
}