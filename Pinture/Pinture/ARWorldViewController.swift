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
import FirebaseStorage
import Photos
import AVFoundation

class ARViewController: UIViewController, ARSCNViewDelegate, SKViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var btnPlus: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    @objc let locationManager = CLLocationManager()
    var currentLatitude, currentLongitude : CLLocationDegrees?
    var showingObjectSequenceList : NSMutableArray = []
    var virtualObjectList : [VirtualObject] = []
    var photoLibraryViewController : PhotoLibraryViewController?
    
    var inputMessageViewController : InputMessageViewController?
    var imageDetailViewController : ImageDetailViewController?
    var uploadingImageCount = 0
    let networkQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        showingObjectSequenceList.removeAllObjects()
        DataManager.sharedInstance.cntDownloadingMsgImage = 0
        getMsgInfoList {
            for msgInfo in DataManager.sharedInstance.msgInfoList {
                self.loadVirtualObject(sequence: msgInfo.sequence , contentsType: msgInfo.contentsType, contentsUrl: msgInfo.contentsUrl
                    , position: SCNVector3(msgInfo.position_x, msgInfo.position_y, msgInfo.position_z)
                    , eulerAngles: SCNVector3(msgInfo.eulerAngles_x, msgInfo.eulerAngles_y, msgInfo.eulerAngles_z)
                    , scale: SCNVector3(msgInfo.scale_x, msgInfo.scale_y, msgInfo.scale_z) )
            }
            
            if DataManager.sharedInstance.msgInfoList.count > 0 {
                self.playSound(name: "welcome")
            }
        }
        setupSceneView()
        setupUIControls()
    }
    
    @IBAction func onTouchBtnStop(_ sender: Any) {
        var originNodeCount = 0
        for msgInfo in DataManager.sharedInstance.msgInfoList {
            if msgInfo.state == 0 {
                originNodeCount += 1
            }
        }
        
        guard originNodeCount != DataManager.sharedInstance.msgInfoList.count else {
            self.networkQueue.cancelAllOperations()
            self.goToMapViewController()
            return
        }
        
        self.showExitAlertView()
    }
    
    @IBAction func onTouchBtnPlus(_ sender: Any) {
        
        
        let photoLibraryVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "photoLibrary") as! PhotoLibraryViewController
        self.addChildViewController(photoLibraryVc)
        photoLibraryVc.view.frame = self.view.frame
        self.photoLibraryViewController = photoLibraryVc
        
        self.view.addSubview(self.photoLibraryViewController!.view)
        self.photoLibraryViewController!.didMove(toParentViewController: self)
        
        
    }
    
    @IBAction func onTouchBtnSave(_ sender: Any) {
        virtualObject?.index = DataManager.sharedInstance.msgInfoList.count
        if DataManager.sharedInstance.isVideoMode {
            DataManager.sharedInstance.msgInfoList.append(
                ( DataManager.sharedInstance.dataModule.currentSequence
                    , DataManager.sharedInstance.currentWorldInfo!.world_sequence
                    , currentLatitude!, currentLongitude!
                    , virtualObject!.position.x, virtualObject!.position.y, virtualObject!.position.z
                    , virtualObject!.eulerAngles.x, virtualObject!.eulerAngles.y, virtualObject!.eulerAngles.z
                    , virtualObject!.scale.x, virtualObject!.scale.y, virtualObject!.scale.z
                    , virtualObject!.contentsType
                    , virtualObject!.pickedVideoUrl
                    , virtualObject!.pickedImage
                    , virtualObject!.pickedVideo
                    , virtualObject!.extensionName
                    , 1))
        } else {
            DataManager.sharedInstance.msgInfoList.append(
                ( DataManager.sharedInstance.dataModule.currentSequence
                    , DataManager.sharedInstance.currentWorldInfo!.world_sequence
                    , currentLatitude!, currentLongitude!
                    , virtualObject!.position.x, virtualObject!.position.y, virtualObject!.position.z
                    , virtualObject!.eulerAngles.x, virtualObject!.eulerAngles.y, virtualObject!.eulerAngles.z
                    , virtualObject!.scale.x, virtualObject!.scale.y, virtualObject!.scale.z
                    , virtualObject!.contentsType
                    , URL(string: "http://www.naver.com" )!
                    , virtualObject!.pickedImage
                    , virtualObject!.pickedVideo
                    , virtualObject!.extensionName
                    , 1))
        }
        DataManager.sharedInstance.pickedImage = nil
        virtualObject?.sequence = DataManager.sharedInstance.dataModule.currentSequence
        
        if virtualObject is PictureFrame {
            let object = virtualObject as! PictureFrame
            virtualObjectList.append(object)
            self.pinAnimate(object : object)
        } else if virtualObject is PictureFrameSecond {
            let object = virtualObject as! PictureFrameSecond
            virtualObjectList.append(object)
            self.pinAnimate(object : object)
        } else if virtualObject is VideoFrameFirst {
            let object = virtualObject as! VideoFrameFirst
            virtualObjectList.append(object)
            self.pinAnimate(object : object)
        } else if virtualObject is VideoFrameSecond {
            let object = virtualObject as! VideoFrameSecond
            virtualObjectList.append(object)
            self.pinAnimate(object : object)
        }
        
        virtualObject = nil
        btnSave.isHidden = true
        btnDelete.isHidden = true
        DataManager.sharedInstance.dataModule.currentSequence += 1
    }
    
    @IBAction func onTouchBtnDelete(_ sender: Any) {
        resetVirtualObject()
        DispatchQueue.main.async {
            self.btnSave.isHidden = true
            self.btnDelete.isHidden = true
        }
        self.playSound(name: "delete")
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
    @IBOutlet var sceneView: ARSCNView!
    
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
            self.screenCenter = self.sceneView?.bounds.mid
        }
        
        if let camera = sceneView?.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        
        
        
    }
    
    func setupUIControls() {
        btnPlus.setImage(#imageLiteral(resourceName: "add"), for: [])
        btnPlus.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        
        btnStop.layer.cornerRadius = btnStop.bounds.size.width/2;
        btnStop.layer.masksToBounds = true;
        
        let photoLibraryVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "photoLibrary") as! PhotoLibraryViewController
        self.addChildViewController(photoLibraryVc)
        photoLibraryVc.view.frame = self.view.frame
        self.photoLibraryViewController = photoLibraryVc
        
        let inputMessageVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inputMessage") as! InputMessageViewController
        self.addChildViewController(inputMessageVc)
        inputMessageVc.view.frame = self.view.frame
        self.inputMessageViewController = inputMessageVc
        
        
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            self.sceneView?.scene.lightingEnvironment.intensity = 25
            self.playVideoObjectByDistance()
        }
    }
    
    
    
    
    
    // MARK: - Current Location
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        currentLatitude     = locValue.latitude
        currentLongitude    = locValue.longitude
        
    }
    
    override func viewDidLayoutSubviews() {
        switch DataManager.sharedInstance.viewState {
        case .ImageDetail:
            guard let imageDetailVc = self.imageDetailViewController else { return }
            if !self.view.subviews.contains(imageDetailVc.view) {
                self.virtualObject = nil
            }
            break
        case .ImageDetailSaved:
            print("index : ", virtualObject?.index)
            if DataManager.sharedInstance.msgInfoList[virtualObject!.index].state == 1 {
                DataManager.sharedInstance.msgInfoList[virtualObject!.index].state = 0
                print("index : new \(virtualObject?.index)")
            } else {
                DataManager.sharedInstance.msgInfoList[virtualObject!.index].state = -1
                print("index : old \(virtualObject?.index)")
            }
            self.resetVirtualObject()
            break
        case .InputMessage:
            if DataManager.sharedInstance.currentWorldInfo?.message != "" {
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd"
                DataManager.sharedInstance.currentWorldInfo?.time = formatter.string(from: date)
                self.uploadWorld()
            }
            break
        case .photoLibrary:
            if DataManager.sharedInstance.pickedImage == nil {
                resetVirtualObject()
                DispatchQueue.main.async {
                    self.btnSave.isHidden = true
                    self.btnDelete.isHidden = true
                }
            } else {
                loadVirtualObject()
            }
            break
        case .AR:
            break;
        }
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
                    
                    let imageDetailVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "imageDetail") as! ImageDetailViewController
                    self.addChildViewController(imageDetailVc)
                    imageDetailVc.view.frame = self.view.frame
                    
                    if virtualObject!.contentsType <= 10 {
                        imageDetailVc.imageView.image = virtualObject?.pickedImage
                        imageDetailVc.labelTitle.text = "사진"
                    } else {
                        let imgGenerator = AVAssetImageGenerator(asset: virtualObject!.pickedVideo)
                        do {
                            let videoFrame = virtualObject as! VideoFrame
                            let seconds = Int(CMTimeGetSeconds(videoFrame.playerItem.duration))
                            let minute = seconds / 60
                            let second = seconds % 60
                            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                            let thumbnailImage = UIImage(cgImage: cgImage)
                            
                            guard let assetVideoTrack = videoFrame.pickedVideo.tracks(withMediaType: AVMediaType.video).last else {return}
                            let videoTransform = assetVideoTrack.preferredTransform
                            
                            if(videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0)  {
                                imageDetailVc.imageView.image = self.imageRotatedByDegrees(oldImage: thumbnailImage, deg: 90)
                                print("right")
                            } else if(videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0)  {
                                imageDetailVc.imageView.image = self.imageRotatedByDegrees(oldImage: thumbnailImage, deg: -90)
                                print("left")
                            } else if(videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0)   {
                                imageDetailVc.imageView.image = thumbnailImage
                                print("up")
                            } else if(videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
                                imageDetailVc.imageView.image = self.imageRotatedByDegrees(oldImage: thumbnailImage, deg: 180)
                                print("down")
                            }
                            
                            imageDetailVc.videoUrl = virtualObject?.pickedVideoUrl
                            imageDetailVc.labelTime.text = String(format: "%02d:%02d", minute, second)
                            imageDetailVc.labelTitle.text = "동영상"
                        } catch let error {
                            print(error.localizedDescription)
                        }
                    }
                    
                    self.imageDetailViewController = imageDetailVc
                    self.view.addSubview(self.imageDetailViewController!.view)
                    self.imageDetailViewController!.didMove(toParentViewController: self)
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
    
    
    
    
    
    
    
    func playVideoObjectByDistance() {
        let cam : ARCamera
        for node in self.sceneView.scene.rootNode.childNodes {
            if node is VideoFrame {
                guard let camera = session.currentFrame?.camera else {return}
                let cameraTransform = camera.transform
                let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
                let vectorToCamera = cameraPos - node.position
                let distanceToUser = vectorToCamera.length()
                
                let video = node as! VideoFrame
                if video != nil
                    && video.player != nil
                    && video.player.error == nil {
                    
                    let diff = abs(camera.eulerAngles.x - video.eulerAngles.x) + abs(camera.eulerAngles.y - video.eulerAngles.y)
                    let reduced = ((distanceToUser - 1) / 2 ) + diff
                    
                    if reduced < 1 {
                        if video.player.rate == 0 {
                            video.player.play()
                        } else {
                            video.player.volume = 1 - reduced
                        }
                    } else {
                        if video.player.rate != 0 {
                            video.player.pause()
                        }
                    }
                }
            }
        }
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
        if virtualObject is VideoFrame {
            let video = virtualObject as! VideoFrame
            video.player.pause()
            video.player = nil
        }
        
        DataManager.sharedInstance.pickedVideoUrl = nil
        DataManager.sharedInstance.pickedExtensionName = nil
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
    
    func loadVirtualObject() {
        guard let image     = DataManager.sharedInstance.pickedImage            else {return}
        guard let ext       = DataManager.sharedInstance.pickedExtensionName    else {return}
        let videoUrl  = DataManager.sharedInstance.pickedVideoUrl
        
        resetVirtualObject()
        
        // Load the content asynchronously.
        DispatchQueue.global().async {
            
            self.isLoadingObject = true
            
            if DataManager.sharedInstance.isVideoMode {
                
                let video = AVAsset(url: videoUrl!)
                guard let videoTrack = video.tracks(withMediaType: AVMediaType.video).first else {return}
                let size = videoTrack.naturalSize
                let txf = videoTrack.preferredTransform
                let realVidSize = size.applying(txf)
                
                var object : VideoFrame!
                if abs(realVidSize.width) < abs(realVidSize.height) {
                    object = VideoFrameFirst(video: video, videoUrl: videoUrl!, extensionName: ext)
                } else {
                    object = VideoFrameSecond(video: video, videoUrl: videoUrl!, extensionName: ext)
                }
                
                self.virtualObject = object
                object.viewController = self
                object.loadModel()
                
                object.player.play()
                
                
            } else {
                var pictureObject : VirtualObject
                if image.size.width < image.size.height {
                    pictureObject  = PictureFrame(pickedImage: image, extensionName: ext)
                } else {
                    pictureObject  = PictureFrameSecond(pickedImage: image, extensionName: ext)
                }
                pictureObject.viewController = self
                self.virtualObject = pictureObject
                
                pictureObject.loadModel()
            }
            DispatchQueue.main.async {
                self.btnSave.isHidden = false
                self.btnDelete.isHidden = false
                // Immediately place the object in 3D space.
                self.setNewVirtualObjectPosition( SCNVector3(0, 0, 1) )
                
                // Update loading flag of the add object button
                self.isLoadingObject = false
            }
        }
    }
    
    func loadVirtualObject(sequence : Int, image : UIImage, position : SCNVector3, eulerAngles : SCNVector3, scale : SCNVector3) {
        
        // Load the content asynchronously.
        DispatchQueue.global().async {
            
            if self.showingObjectSequenceList.contains(sequence) {
                return
            }
            self.showingObjectSequenceList.add(sequence)
            
            self.loadImageModel(index: sequence - 1, image: image, position: position, eulerAngles: eulerAngles, scale: scale)
            self.resetVirtualObject()
        }
    }
    
    func loadVirtualObject(sequence : Int, contentsType : Int, contentsUrl : URL, position : SCNVector3, eulerAngles : SCNVector3, scale : SCNVector3) {
        // Load the content asynchronously.
        DispatchQueue.global().async {
            if self.showingObjectSequenceList.contains(sequence) {
                return
            }
            self.showingObjectSequenceList.add(sequence)
            
            let index = DataManager.sharedInstance.msgInfoList.map{ $0.sequence }.index(of: sequence)!
            if index >= DataManager.sharedInstance.msgInfoList.count {
                self.tabBarController?.selectedIndex = 1
            }
            
            
            if DataManager.sharedInstance.msgInfoList[index].contentsType <= 10 {
                
                if DataManager.sharedInstance.msgInfoList[index].image == nil {
                    self.networkQueue.addOperation {
                        print("Image is downloading...")
                        DispatchQueue.main.async {
                            self.activityIndicatorView.startAnimating()
                        }
                        DataManager.sharedInstance.cntDownloadingMsgImage += 1
                        
                        
                        // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
                        let urlSession = URLSession(configuration: .default)
                        let downloadPicTask = urlSession.dataTask(with: contentsUrl) { (data, response, error) in
                            
                            
                            // The download has finished.
                            if let e = error {
                                print("Error downloading cat picture: \(e)")
                            } else {
                                // No errors found.
                                // It would be weird if we didn't have a response, so check for that too.
                                if let res = response as? HTTPURLResponse {
                                    if DataManager.sharedInstance.msgInfoList.count == 0 { return }
                                    print("Downloaded cat picture with response code \(res.statusCode)")
                                    if let contentsData = data {
                                        
                                        // Finally convert that Data into an image and do what you wish with it.
                                        DataManager.sharedInstance.msgInfoList[index].image = UIImage(data: contentsData)
                                        self.loadImageModel(index: index, image: DataManager.sharedInstance.msgInfoList[index].image!, position: position, eulerAngles: eulerAngles, scale: scale)
                                        
                                        DataManager.sharedInstance.cntDownloadingMsgImage -= 1
                                        if DataManager.sharedInstance.cntDownloadingMsgImage == 0 {
                                            DispatchQueue.main.async {
                                                self.activityIndicatorView.stopAnimating()
                                            }
                                        }
                                        
                                        
                                    } else {
                                        print("Couldn't get image: Image is nil")
                                    }
                                } else {
                                    print("Couldn't get response code for some reason")
                                }
                            }
                        }
                        
                        downloadPicTask.resume()
                    }
                } else {
                    // Finally convert that Data into an image and do what you wish with it.
                    self.loadImageModel(index: index, image: DataManager.sharedInstance.msgInfoList[index].image!, position: position, eulerAngles: eulerAngles, scale: scale)
                }
            } else {
                self.loadVideoModel(index: index, videoUrl: DataManager.sharedInstance.msgInfoList[index].contentsUrl, position: position, eulerAngles: eulerAngles, scale: scale)
            }
            
        }
    }
    
    
    
    func loadImageModel(index : Int, image : UIImage, position : SCNVector3, eulerAngles : SCNVector3, scale : SCNVector3 ) {
        var pictureObject : VirtualObject
        if image.size.width < image.size.height {
            pictureObject = PictureFrame(pickedImage: image, extensionName: DataManager.sharedInstance.msgInfoList[index].extensionName!)
        } else {
            pictureObject = PictureFrameSecond(pickedImage: image, extensionName: DataManager.sharedInstance.msgInfoList[index].extensionName!)
        }
        
        pictureObject.viewController = self
        pictureObject.index = index
        pictureObject.loadModel()
        
        DispatchQueue.main.async {
            
            pictureObject.position = position
            pictureObject.eulerAngles = eulerAngles
            pictureObject.scale = scale
            
            self.sceneView?.scene.rootNode.addChildNode(pictureObject)
        }
    }
    
    func loadVideoModel(index : Int, videoUrl : URL, position : SCNVector3, eulerAngles : SCNVector3, scale : SCNVector3 ) {
        
        networkQueue.addOperation {
            let video = AVAsset(url: videoUrl)
            
            if DataManager.sharedInstance.msgInfoList.count == 0 { return }
            DataManager.sharedInstance.msgInfoList[index].video = video
            
            var object : VideoFrame!
            if DataManager.sharedInstance.msgInfoList.count == 0 { return }
            if DataManager.sharedInstance.msgInfoList[index].contentsType == 11 {
                object = VideoFrameFirst(video: video, videoUrl: videoUrl, extensionName: DataManager.sharedInstance.msgInfoList[index].extensionName!)
            } else {
                object = VideoFrameSecond(video: video, videoUrl: videoUrl, extensionName: DataManager.sharedInstance.msgInfoList[index].extensionName!)
            }
            
            
            object.viewController = self
            object.index = index
            object.loadModel()
            
            DispatchQueue.main.async {
                
                object.position = position
                object.eulerAngles = eulerAngles
                object.scale = scale
                
                self.sceneView?.scene.rootNode.addChildNode(object)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        self.showPermissionDeniedAlertView(title : "세션 만료", message : "세션이 만료되어 홈 화면으로 이동합니다.", completionHandler: {
            self.goToMapViewController()
        })
    }
    
    
    func pinAnimate(object : VirtualObject)
    {
        object.showPinAnimation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.playSound(name: "pin")
            object.showPinnedAnimation()
        }
    }
    
    
    var player: AVAudioPlayer?
    
    func playSound(name : String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    func goToMapViewController() {
        for node in self.sceneView.scene.rootNode.childNodes {
            if node is VideoFrame {
                let video = node as! VideoFrame
                video.player.pause()
                video.player = nil
            }
        }
        
        DataManager.sharedInstance.currentWorldIndex = -1
        
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
    
    func saveInfo() {
        
        if DataManager.sharedInstance.currentWorldIndex == -1 {
            let inputMessageVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inputMessage") as! InputMessageViewController
            self.addChildViewController(inputMessageVc)
            inputMessageVc.view.frame = self.view.frame
            self.inputMessageViewController = inputMessageVc
            self.view.addSubview(self.inputMessageViewController!.view)
            self.inputMessageViewController!.didMove(toParentViewController: self)
        } else {
            self.uploadMsg()
        }
    }
    
    func uploadWorld() {
        
        self.activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        uploadWorldInfo(viewController: self, completionHandler: {
            self.goToMapViewController()
            self.activityIndicatorView.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        })
    }
    
    func uploadMsg() {
        self.activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        uploadMsgInfo(viewController: self, completionHandler: {
            self.goToMapViewController()
            self.activityIndicatorView.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        })
    }
    
    func updateCompletePercent(sequence : Int, completionPercent : Int) {
        for object in virtualObjectList {
            if object.sequence == sequence {
                DispatchQueue.main.async {
                    object.showPercentage(percent: completionPercent)
                }
                return
            }
        }
    }
    
    func updateComplete(sequence : Int) {
        for object in virtualObjectList {
            if object.sequence == sequence {
                DispatchQueue.main.async {
                    object.stopPercentage()
                }
                return
            }
        }
    }
    
    func showExitAlertView() {
        let alert = UIAlertController(title: "", message: "월드를 저장하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "저장", style: UIAlertActionStyle.default, handler: { action in
            if action.style == .default{
                self.saveInfo()
            }
        }))
        alert.addAction(UIAlertAction(title: "저장 안함", style: UIAlertActionStyle.default, handler: { action in
            if action.style == .default{
                self.goToMapViewController()
            }
        }))
        alert.addAction(UIAlertAction(title: "취소", style: UIAlertActionStyle.cancel, handler: { action in
            alert.dismiss(animated: true, completion: {})
        }))
        self.present(alert, animated: true, completion: {
            alert.view.superview?.isUserInteractionEnabled = true
            alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
        })
    }
    
    @objc func alertControllerBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
}
