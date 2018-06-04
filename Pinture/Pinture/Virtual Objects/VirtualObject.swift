//
//  VirtualObject.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 10..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class VirtualObject: SCNNode {
    
    @objc var contentsType = 1
    @objc var modelName: String = ""
    @objc var fileExtension: String = ""
    @objc var pickedImage: UIImage!
    @objc var pickedVideo : AVAsset!
    var pickedVideoUrl : URL!
    var index : Int = -1
    var sequence : Int = -1
    var percentNode : SCNNode?
    var pinAnimationNode : SCNNode?
    var albumNode : SCNNode?
    @objc var title: String = ""
    @objc var extensionName: String = ""
    @objc var modelLoaded: Bool = false
    @objc var virtualObjectScene : SCNScene?
    
    @objc var viewController: ARViewController?
    
    @objc init(pickedImage : UIImage, extensionName : String) {
        super.init()
        self.pickedImage = pickedImage
        self.extensionName = extensionName.trimmingCharacters(in: CharacterSet.whitespaces)
        self.name = "Virtual object root node"
    }
    
    @objc init(video : AVAsset, videoUrl : URL, extensionName : String) {
        super.init()
        self.pickedVideo = video
        self.pickedVideoUrl = videoUrl
        self.extensionName = extensionName.trimmingCharacters(in: CharacterSet.whitespaces)
        
        self.name = "Virtual object root node"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func loadModel() {
        let wrapperNode = SCNNode()
        
        guard let virtualObject = self.virtualObjectScene else {return}
        for child in virtualObject.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            child.movabilityHint = .movable
            wrapperNode.addChildNode(child)
        }
        self.addChildNode(wrapperNode)
        
        modelLoaded = true
    }
    
    @objc func unloadModel() {
        for child in self.childNodes {
            child.removeFromParentNode()
        }
        
        modelLoaded = false
    }
    
    @objc func translateBasedOnScreenPos(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        
        guard let controller = viewController else {
            return
        }
        
        let result = controller.worldPositionFromScreenPosition(pos, objectPos: self.position, infinitePlane: infinitePlane)
        
        controller.moveVirtualObjectToPosition(result.position, instantly, !result.hitAPlane)
    }
    
    func showPinAnimation() {
        
        pinAnimationNode?.removeFromParentNode()
        let pinScene = SCNScene(named: "pin.dae", inDirectory: "art.scnassets")
        guard let pinObject = pinScene else { return }
        pinAnimationNode = pinObject.rootNode.childNode(withName: "SketchUp", recursively: true)
        self.addChildNode(pinAnimationNode!)
        
        let pinAnimation = CABasicAnimation(keyPath: "position")
        guard let pos = pinAnimationNode?.position else { return }
        
        pinAnimation.fromValue = NSValue(scnVector4: SCNVector4(x: pos.x - 0.2, y: pos.y, z: pos.z + 0.2, w: 0))
        pinAnimation.toValue = NSValue(scnVector4: SCNVector4(x: pos.x, y: pos.y, z: pos.z, w: 0))
        pinAnimation.duration = 1
        pinAnimationNode?.addAnimation(pinAnimation, forKey: "pinAnimation")
    }
    
    func showPinnedAnimation() {
        let particle = SCNParticleSystem(named: "pinned.scnp", inDirectory: "art.scnassets")
        particle?.birthLocation = .surface
        particle?.emitterShape = self.albumNode!.geometry
        self.albumNode!.addParticleSystem(particle!)
        
        
        let removeParticle = SCNAction.run { _ in
            self.albumNode!.removeParticleSystem(particle!)
        }
        let sequence = SCNAction.sequence([SCNAction.fadeIn(duration: 0.8), removeParticle])
        runAction(sequence)
    }
    
    func showPercentage(percent : Int) {
        
        percentNode?.removeFromParentNode()
        let newText = SCNText(string: "\(percent)%", extrusionDepth: 0.1)
        newText.font = UIFont (name: "Arial", size: 0.5)
        newText.firstMaterial!.diffuse.contents = UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
        
        percentNode = SCNNode(geometry: newText)
        percentNode?.scale = SCNVector3( 0.2, 0.2, 0.2 )
        self.addChildNode(percentNode!)
    }
    
    func stopPercentage() {
        percentNode?.removeFromParentNode()
        let newText = SCNText(string: "업로드 완료!", extrusionDepth: 0)
        newText.font = UIFont (name: "Arial", size: 0.5)
        newText.firstMaterial!.diffuse.contents = UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
        
        percentNode = SCNNode(geometry: newText)
        percentNode?.scale = SCNVector3( 0.2, 0.2, 0.2 )
        self.addChildNode(percentNode!)
    }
}

extension VirtualObject {
    
    @objc static func isNodePartOfVirtualObject(_ node: SCNNode) -> Bool {
        if node.name == "Virtual object root node" {
            return true
        }
        
        if node.parent != nil {
            return isNodePartOfVirtualObject(node.parent!)
        }
        
        return false
    }
}

// MARK: - Protocols for Virtual Objects

protocol ReactsToScale {
    func reactToScale()
}

extension SCNNode {
    
    func reactsToScale() -> ReactsToScale? {
        if let canReact = self as? ReactsToScale {
            return canReact
        }
        
        if parent != nil {
            return parent!.reactsToScale()
        }
        
        return nil
    }
}
