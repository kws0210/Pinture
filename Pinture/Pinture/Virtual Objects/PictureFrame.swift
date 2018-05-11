//
//  MapViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 4. 19..
//  Copyright © 2018년 Sogang. All rights reserved.
//


import Foundation
import SceneKit

class PictureFrame : VirtualObject, ReactsToScale {
    
    override init(pickedImage : UIImage, extensionName : String) {
        super.init(pickedImage: pickedImage, extensionName : extensionName)
        
        virtualObjectScene = SCNScene(named: "picture_frame.dae", inDirectory: "art.scnassets")
        
        guard let virtualObject = virtualObjectScene else { return }
        let objectNode = virtualObject.rootNode.childNode(withName: "Picture_01", recursively: true)
        
        if let albumNode = objectNode?.childNode(withName: "ID132", recursively: false) {
            self.albumNode = albumNode
            let material_L = albumNode.geometry?.material(named: "Picture_02")
            material_L!.diffuse.contents = pickedImage
            material_L!.locksAmbientWithDiffuse = true;
            albumNode.geometry?.replaceMaterial(at: 1, with: material_L!)
        }
        
        self.contentsType = 1
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


