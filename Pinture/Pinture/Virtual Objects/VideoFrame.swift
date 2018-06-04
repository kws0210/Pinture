//
//  VideoFrame.swift
//  Pinture
//
//  Created by Team7 on 2018. 6. 4..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit
import AVFoundation

class VideoFrame : VirtualObject, ReactsToScale, AVAssetDownloadDelegate {
    var playerItem : AVPlayerItem!
    var player : AVPlayer!
    var videoSize : CGSize!
    var videoUrl : URL!

    override init(video : AVAsset, videoUrl : URL, extensionName : String) {
        super.init(video: video, videoUrl : videoUrl, extensionName : extensionName)
        
        playerItem = AVPlayerItem(asset: pickedVideo)
        player = AVPlayer(playerItem: playerItem)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        print("timeRangeExpectedToLoad : ", timeRangeExpectedToLoad)
    }
    
    @objc func reactToScale() {
        // Update the size of the flame
        let flameNode = self.childNode(withName: "flame", recursively: true)
        let particleSize: Float = 0.018
        flameNode?.particleSystems?.first?.reset()
        flameNode?.particleSystems?.first?.particleSize = CGFloat(self.scale.x * particleSize)
    }
}
