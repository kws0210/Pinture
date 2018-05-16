//
//  StartingLocationViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 16..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import FirebaseStorage
import GoogleMaps

class StartingLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var bgEntrance: UIView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var hintView: UIView!
    @IBOutlet var btnARWorld: UIButton!
    @IBOutlet var textDescription: UITextView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    @objc let locationManager = CLLocationManager()
    var currentLatitude, currentLongitude : CLLocationDegrees?
    var currentImage : UIImage?
    var isInExistingArea = false
    let cameraController = CameraController()
    var worldListViewController : WorldListViewController?
    var enterWorldIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func configureCameraController() {
            cameraController.prepare {(error) in
                if let error = error {
                    print(error)
                }
                
                try? self.cameraController.displayPreview(on: self.previewView)
            }
        }
        configureCameraController()
        
        
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        
        if enterWorldIndex == -1 {
            getNearWorldData(latitude: currentLatitude!, longitude: currentLongitude!, completionHandler: {
                
                if DataManager.sharedInstance.nearWorldInfoList.count != 0 {
                    self.showWorldList()
                } else {
                    DispatchQueue.main.async {
                        self.btnARWorld.isHidden = false
                        self.textDescription.isHidden = false
                        self.bgEntrance.isHidden = false
                    }
                }
            })
        } else {
            let world = DataManager.sharedInstance.worldInfoList[enterWorldIndex]
            DataManager.sharedInstance.currentWorldIndex = self.enterWorldIndex
            self.downloadHintImageUrl(strImageUrl: world.imageUrl)
        }
    }
    
    override func viewDidLayoutSubviews() {
        guard let vc = self.worldListViewController else { return }
        if !self.view.subviews.contains(vc.view) {
            if DataManager.sharedInstance.currentWorldIndex == -1 {
                DispatchQueue.main.async {
                    self.btnARWorld.isHidden = false
                    self.textDescription.isHidden = false
                    self.bgEntrance.isHidden = false
                }
            } else {
                let world = DataManager.sharedInstance.nearWorldInfoList[DataManager.sharedInstance.currentWorldIndex]
                DataManager.sharedInstance.dataModule.currentWorldSequence = world.world_sequence
                
                checkWorldExist(worldSequence: world.world_sequence, posCompletion: {
                    let hintImageUrl = DataManager.sharedInstance.nearWorldInfoList[DataManager.sharedInstance.currentWorldIndex].imageUrl
                    self.downloadHintImageUrl(strImageUrl: hintImageUrl)
                }, negCompletion: {
                    self.showMessageAlertView(message: "삭제된 월드입니다.", completionHandler: {
                        self.dismiss(animated: true, completion: {})
                    })
                })
            }
        }
    }
    

    @IBAction func onTouchBtnARWorld(_ sender: Any) {
        if DataManager.sharedInstance.nearWorldInfoList.count == 0
            || DataManager.sharedInstance.currentWorldIndex == -1 {
            cameraController.captureImage {(image, error) in
                guard let image = image else {
                    print(error ?? "Image capture error")
                    return
                }
                
                self.currentImage = image
                self.saveCurrentWorldInfo(image: self.currentImage!)
                self.goToARViewController()
            }
        } else {
            self.saveCurrentWorldInfo(image: self.currentImage!)
            self.goToARViewController()
        }
        
    }
    
    func downloadHintImageUrl( strImageUrl : String) {
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: strImageUrl)
        
        self.activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        storageRef.downloadURL(completion: { (imageUrl, error) in
            if error != nil {
                print(error)
            } else {
                self.downloadHintImage(imageUrl: imageUrl!)
            }
        })
    }
    
    func downloadHintImage( imageUrl : URL) {
        print("Hint image is downloading...")
        // Creating a session object with the default configuration.
        // You can read more about it here https://developer.apple.com/reference/foundation/urlsessionconfiguration
        let session = URLSession(configuration: .default)
        
        // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
        let downloadPicTask = session.dataTask(with: imageUrl) { (data, response, error) in
            
            
            // The download has finished.
            if let e = error {
                print("Error downloading cat picture: \(e)")
            } else {
                // No errors found.
                // It would be weird if we didn't have a response, so check for that too.
                if let res = response as? HTTPURLResponse {
                    print("Downloaded cat picture with response code \(res.statusCode)")
                    if let imageData = data {
                        let image = UIImage(data: imageData)
                        self.currentImage = image
                        
                        DispatchQueue.main.async {
                            // Finally convert that Data into an image and do what you wish with it.
                            UIGraphicsBeginImageContext(self.hintView.frame.size)
                            image?.draw(in: self.hintView.bounds)
                            let sizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                            UIGraphicsEndImageContext()
                            self.hintView.backgroundColor = UIColor(patternImage: sizedImage)
                            DispatchQueue.main.async {
                                let index = DataManager.sharedInstance.currentWorldIndex
                                let name = DataManager.sharedInstance.worldInfoList[index].message
                                self.btnARWorld.setTitle("입장하기", for: .normal)
                                self.textDescription.text = "\'\(name)\'월드의 입장 화면을 맞춘 후\n[입장하기]버튼을 클릭해주세요."
                                self.btnARWorld.isHidden = false
                                self.textDescription.isHidden = false
                                self.bgEntrance.isHidden = false
                            }
                            self.activityIndicatorView.stopAnimating()
                            UIApplication.shared.endIgnoringInteractionEvents()
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
    
    func saveCurrentWorldInfo(image : UIImage) {
        DataManager.sharedInstance.currentWorldInfo = (world_sequence: DataManager.sharedInstance.dataModule.currentWorldSequence, latitude: currentLatitude!, longitude: currentLongitude!, image: image, message: "", time: "")
        
    }
    
    func goToARViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ARWorldViewController")
        self.present(vc, animated: true, completion: nil)
    }
    
    func showWorldList() {
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "worldList") as! WorldListViewController
        
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.worldListViewController = popOverVC
        
        self.view.addSubview(worldListViewController!.view)
        worldListViewController!.didMove(toParentViewController: self)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        currentLatitude     = locValue.latitude
        currentLongitude    = locValue.longitude
    }
    
    
    func showMessageAlertView(message : String, completionHandler : (()->Void)!) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: { action in
            print("showMessageAlertView")
            completionHandler()
        }))
        self.present(alert, animated: true, completion: {
            alert.view.superview?.isUserInteractionEnabled = true
        })
    }

}

