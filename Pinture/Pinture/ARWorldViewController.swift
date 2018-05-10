//
//  ARWorldViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 10..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import GoogleMaps
import Photos

class ARWorldViewController: UIViewController, ARSCNViewDelegate, SKViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate {
    
    var currentLatitude, currentLongitude : CLLocationDegrees?
    var showingObjectSequenceList : NSMutableArray = []
    var virtualObjectList : [VirtualObject] = []
    var photoLibraryViewController : PhotoLibraryViewController?

    @IBOutlet weak var btnPlus: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        
        // Start the ARSession.
        sceneView?.session.run(sessionConfig)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView?.session.pause()
    }
    
    
    // MARK: - ARKit / ARSCNView
    var session = ARSession()
    var sessionConfig: ARConfiguration = ARWorldTrackingConfiguration() {
        didSet {
            sessionConfig.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
            
        }
    }
    
    var screenCenter: CGPoint?
    @IBOutlet weak var sceneView: ARSCNView!
    
    func setupSceneView() {
        
        // set up sceneView
        sceneView?.delegate = self
        sceneView?.session = session
        sceneView?.antialiasingMode = .multisampling4X
        sceneView?.automaticallyUpdatesLighting = false
        sceneView?.preferredFramesPerSecond = 60
        sceneView?.contentScaleFactor = 1.3
        sceneView?.scene.lightingEnvironment.intensity = 25
        
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView?.center
        }
        
        if let camera = sceneView?.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            self.sceneView?.scene.lightingEnvironment.intensity = 25
        }
    }
    
    @IBAction func onTouchBtnStop(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTouchBtnPlus(_ sender: Any) {
        let photoLibraryVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "photoLibrary") as! PhotoLibraryViewController
        self.addChildViewController(photoLibraryVc)
        photoLibraryVc.view.frame = self.view.frame
        self.photoLibraryViewController = photoLibraryVc
        
        self.view.addSubview(self.photoLibraryViewController!.view)
        self.photoLibraryViewController!.didMove(toParentViewController: self)
    }
    
    // MARK: - Gesture Recognizers
    
    var currentGesture: Gesture?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let object = virtualObject {
            
            if currentGesture == nil {
                currentGesture = Gesture.startGestureFromTouches(touches, self.sceneView!, object)
            } else {
                currentGesture = currentGesture!.updateGestureFromTouches(touches, .touchBegan)
            }
            
            displayVirtualObjectTransform()
        } else {
            var hitTestOptions = [SCNHitTestOption: Any]()
            hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
            let results: [SCNHitTestResult] = sceneView.hitTest((touches.first?.location(in: sceneView))!, options: hitTestOptions)
            for result in results {
                if VirtualObject.isNodePartOfVirtualObject(result.node) {
                    var object = result.node
                    while !(object is VirtualObject) {
                        object = object.parent!
                    }
                    self.virtualObject = object as! VirtualObject

                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObject == nil {
            return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)
        displayVirtualObjectTransform()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObject == nil {
            return
        }
        
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObject == nil {
            return
        }
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
    }
    
    
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - Virtual Object Manipulation
    
    func displayVirtualObjectTransform() {
        
        guard let object = virtualObject, let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }
        
        // Output the current translation, rotation & scale of the virtual object as text.
        
        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        let vectorToCamera = cameraPos - object.position
        
        let distanceToUser = vectorToCamera.length()
        
        var angleDegrees = Int(((object.eulerAngles.y) * 180) / Float.pi) % 360
        if angleDegrees < 0 {
            angleDegrees += 360
        }
        
        let distance = String(format: "%.2f", distanceToUser)
        let scale = String(format: "%.2f", object.scale.x)
    }
    
    func moveVirtualObjectToPosition(_ pos: SCNVector3?, _ instantly: Bool, _ filterPosition: Bool) {
        
        guard let newPosition = pos else {
            print("CANNOT PLACE OBJECT\nTry moving left or right.")
            // Reset the content selection in the menu only if the content has not yet been initially placed.
            if virtualObject == nil {
                resetVirtualObject()
            }
            return
        }
        
        if instantly {
            setNewVirtualObjectPosition(newPosition)
        } else {
            updateVirtualObjectPosition(newPosition, filterPosition)
        }
    }
    
    var dragOnInfinitePlanesEnabled = false
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView?.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults?.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView!.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, vertical plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView?.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView!.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentVirtualObjectDistances = [CGFloat]()
    
    func setNewVirtualObjectPosition(_ pos: SCNVector3) {
        
        guard let object = virtualObject, let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }
        
        recentVirtualObjectDistances.removeAll()
        
        let cameraAngles = session.currentFrame?.camera.eulerAngles
        let cameraWorldAngles = SCNVector3(cameraAngles!.x, cameraAngles!.y, 0)
        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        cameraToPosition.setMaximumLength(10)
        
        object.position = cameraWorldPos + cameraToPosition
        object.eulerAngles = cameraWorldAngles
        
        if object.parent == nil {
            sceneView?.scene.rootNode.addChildNode(object)
        }
    }
    
    func resetVirtualObject() {
        DataManager.sharedInstance.pickedImage = nil
        virtualObject?.unloadModel()
        virtualObject?.removeFromParentNode()
        virtualObject = nil
    }
    
    func updateVirtualObjectPosition(_ pos: SCNVector3, _ filterPosition: Bool) {
        guard let object = virtualObject else {
            return
        }
        
        guard let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }
        
        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        cameraToPosition.setMaximumLength(10)
        
        // Compute the average distance of the object from the camera over the last ten
        // updates. If filterPosition is true, compute a new position for the object
        // with this average. Notice that the distance is applied to the vector from
        // the camera to the content, so it only affects the percieved distance of the
        // object - the averaging does _not_ make the content "lag".
        let hitTestResultDistance = CGFloat(cameraToPosition.length())
        
        recentVirtualObjectDistances.append(hitTestResultDistance)
        recentVirtualObjectDistances.keepLast(10)
        
        if filterPosition {
            let averageDistance = recentVirtualObjectDistances.average!
            
            cameraToPosition.setLength(Float(averageDistance))
            let averagedDistancePos = cameraWorldPos + cameraToPosition
            
            object.position = averagedDistancePos
        } else {
            object.position = cameraWorldPos + cameraToPosition
        }
    }
    
    
    
    
    
    
    
    
    // MARK: - Virtual Object Loading
    
    var virtualObject: VirtualObject?
    
    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.btnPlus.isEnabled = !self.isLoadingObject
                
                if self.isLoadingObject {
                    self.btnPlus.setImage(#imageLiteral(resourceName: "addPressed"), for: [])
                } else {
                    self.btnPlus.setImage(#imageLiteral(resourceName: "add"), for: [])
                }
            }
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        self.showPermissionDeniedAlertView(title : "세션 만료", message : "세션이 만료되어 홈 화면으로 이동합니다.", completionHandler: {
            self.goToMapViewController()
        })
    }
    
    func goToMapViewController() {
        
        let presentingViewController = self.presentingViewController
        self.dismiss(animated: false, completion: {
            presentingViewController!.dismiss(animated: true, completion: {})
        })
    }
    
    
    func showPermissionDeniedAlertView(title: String, message: String, completionHandler: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: { action in
            if action.style == .default{
                completionHandler?()
            }
        }))
        self.present(alert, animated: true)
    }
    
}
