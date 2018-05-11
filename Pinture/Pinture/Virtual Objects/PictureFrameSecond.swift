//
//  MapViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 4. 19..
//  Copyright © 2018년 Sogang. All rights reserved.
//


import Foundation
import SceneKit

class PictureFrameSecond : VirtualObject, ReactsToScale {

    override init(pickedImage : UIImage, extensionName : String) {
        super.init(pickedImage : pickedImage, extensionName : extensionName)
        
        virtualObjectScene = SCNScene(named: "picture_frame2.dae", inDirectory: "art.scnassets")
        
        guard let virtualObject = virtualObjectScene else { return }
        let objectNode = virtualObject.rootNode.childNode(withName: "Component_2", recursively: true)
        
        if let albumNode = objectNode?.childNode(withName: "group_2", recursively: false) {
            self.albumNode = albumNode
            let material_L = albumNode.geometry?.material(named: "_0007_MistyRose")
            material_L!.diffuse.contents = pickedImage
            material_L!.locksAmbientWithDiffuse = true;
            albumNode.geometry?.replaceMaterial(at: 1, with: material_L!)
        }
        
        self.contentsType = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func reactToScale() {
        // Update the size of the flame
        let flameNode = self.childNode(withName: "flame", recursively: true)
        let particleSize: Float = 0.018
        flameNode?.particleSystems?.first?.reset()
        flameNode?.particleSystems?.first?.particleSize = CGFloat(self.scale.x * particleSize)
    }
}

