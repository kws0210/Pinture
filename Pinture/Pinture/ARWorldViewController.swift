//
//  ARWorldViewController.swift
//  Pinture
//
//  Created by 고원섭 on 2018. 5. 10..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARWorldViewController: UIViewController, ARSCNViewDelegate, SKViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTouchBtnStop(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
    
}
