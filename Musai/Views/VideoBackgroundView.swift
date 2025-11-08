//
//  VideoBackgroundView.swift
//  Musai
//
//  Created by Sun1 on 2025/11/8.
//

import SwiftUI
import AVFoundation
import AVKit

struct VideoBackgroundView: UIViewRepresentable {
    let player: AVQueuePlayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        print("🎬 makeUIView called")
        print("🎬 Player object: \(String(describing: player))")
        
        guard let player = player else {
            print("❌ Video player is nil in VideoBackgroundView")
            return view
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        
        print("✅ Video layer added to view with bounds: \(view.bounds)")
        print("✅ Player layer frame: \(playerLayer.frame)")
        print("✅ Video gravity: \(playerLayer.videoGravity)")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("🎬 updateUIView called")
        
        guard let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer else { 
            print("❌ Player layer not found in updateUIView")
            return 
        }
        
        print("🎬 Updating player layer with bounds: \(uiView.bounds)")
        playerLayer.frame = uiView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.setNeedsDisplay() // 强制刷新
    }
}