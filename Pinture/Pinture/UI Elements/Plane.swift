/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 SceneKit node wrapper for plane geometry detected in AR.
 */

import Foundation
import ARKit

class Plane: SCNNode {
    
    @objc var anchor: ARPlaneAnchor
    @objc var occlusionNode: SCNNode?
    @objc let occlusionPlaneVerticalOffset: Float = -0.01  // The occlusion plane should be placed 1 cm below the actual
    // plane to avoid z-fighting etc.
    
    
    @objc var focusSquare: FocusSquare?
    
    @objc init(_ anchor: ARPlaneAnchor ) {
        self.anchor = anchor
        
        super.init()
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func update(_ anchor: ARPlaneAnchor) {
        self.anchor = anchor
    }
    
    
    
    
    // MARK: Private
    
    private func createOcclusionNode() {
        // Make the occlusion geometry slightly smaller than the plane.
        let occlusionPlane = SCNPlane(width: CGFloat(anchor.extent.x - 0.05), height: CGFloat(anchor.extent.z - 0.05))
        let material = SCNMaterial()
        material.colorBufferWriteMask = []
        material.isDoubleSided = true
        occlusionPlane.materials = [material]
        
        occlusionNode = SCNNode()
        occlusionNode!.geometry = occlusionPlane
        occlusionNode!.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        occlusionNode!.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
        
        self.addChildNode(occlusionNode!)
    }
    
    private func updateOcclusionNode() {
        guard let occlusionNode = occlusionNode, let occlusionPlane = occlusionNode.geometry as? SCNPlane else {
            return
        }
        occlusionPlane.width = CGFloat(anchor.extent.x - 0.05)
        occlusionPlane.height = CGFloat(anchor.extent.z - 0.05)
        
        occlusionNode.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
    }
}


