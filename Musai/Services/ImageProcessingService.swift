//
//  ImageProcessingService.swift
//  Musai
//
//  Created by Sun1 on 2025/11/3.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

class ImageProcessingService: ObservableObject {
    
    func createBlurredBackground(from image: UIImage, radius: CGFloat = 30) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = ciImage
        blurFilter.radius = Float(radius)
        
        guard let outputCIImage = blurFilter.outputImage,
              let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func generateThumbnail(from image: UIImage, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    func createCoverImageWithPlayer(from image: UIImage) -> UIImage? {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background image
            image.draw(in: CGRect(origin: .zero, size: size))
            
            // Add overlay
            let overlayColor = UIColor.black.withAlphaComponent(0.3)
            overlayColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add player icon overlay
            let playerIcon = UIImage(systemName: "play.circle.fill")
            let iconSize: CGFloat = 60
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: size.height - iconSize - 20,
                width: iconSize,
                height: iconSize
            )
            
            UIColor.systemGreen.setFill()
            context.cgContext.fillEllipse(in: iconRect)
            
            if let icon = playerIcon {
                UIColor.white.setFill()
                icon.draw(in: iconRect.insetBy(dx: 15, dy: 15))
            }
        }
    }
}