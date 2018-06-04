//
//  VideoFrameSecond.swift
//  Pinture
//
//  Created by Team7 on 2018. 6. 4..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit
import AVFoundation

class VideoFrameSecond : VideoFrame {

    override init(video : AVAsset, videoUrl : URL, extensionName : String) {
        super.init(video: video, videoUrl: videoUrl, extensionName : extensionName)
        
        setModel()
    }
    
    func setModel() {
        virtualObjectScene = SCNScene(named: "video_frame2.dae", inDirectory: "art.scnassets")
        
        guard let virtualObject = virtualObjectScene else { return }
        let pictureNode = virtualObject.rootNode.childNode(withName: "group_0", recursively: true)
        
        if let albumNode = pictureNode?.childNode(withName: "ID20", recursively: false) {
            self.albumNode = albumNode
            guard let assetVideoTrack = pickedVideo.tracks(withMediaType: AVMediaType.video).last else {return}
            let videoTransform = assetVideoTrack.preferredTransform
            let material_L = albumNode.geometry?.material(named: "material_4")
            let videoNode = SKVideoNode(avPlayer: player)
            let spritescene = SKScene(size: CGSize(width: 3840, height: 720))
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil) { notification in
                guard let plr = self.player else { return }
                plr.seek(to: kCMTimeZero)
                plr.play()
            }
            
            videoNode.position = CGPoint(x: spritescene.size.width/2, y: spritescene.size.height/2)
            videoNode.size.width = spritescene.size.width
            videoNode.size.height = spritescene.size.height
            
            spritescene.addChild(videoNode)
            
            if(videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0)  {
                let translation = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                let rotation = SCNMatrix4MakeRotation(Float.pi / 2, 0, 0, 1)
                let transform = SCNMatrix4Mult(translation, rotation)
                material_L?.diffuse.contentsTransform = transform
                print("right")
            } else if(videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0)  {
                let translation = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                let rotation = SCNMatrix4MakeRotation(-Float.pi / 2, 0, 0, 1)
                let transform = SCNMatrix4Mult(translation, rotation)
                material_L?.diffuse.contentsTransform = transform
                print("left")
            } else if(videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0)   {
                material_L?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                print("up")
            } else if(videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
                let translation = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                let rotation = SCNMatrix4MakeRotation(Float.pi, 0, 0, 1)
                let transform = SCNMatrix4Mult(translation, rotation)
                material_L?.diffuse.contentsTransform = transform
                print("down")
            }
            
            material_L!.diffuse.contents = spritescene
            albumNode.geometry?.replaceMaterial(at: 1, with: material_L!)
        }
        
        self.contentsType = 12
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

