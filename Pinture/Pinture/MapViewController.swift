//
//  MapViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 4. 19..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController, CLLocationManagerDelegate {

    @objc let locationManager = CLLocationManager()
    var currentLatitude, currentLongitude : CLLocationDegrees?
    
    @objc var marker = [GMSMarker]()
    @IBOutlet weak var mapView: GMSMapView!
    
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initiateData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let startingLocationViewController = segue.destination as? StartingLocationViewController {
            startingLocationViewController.currentLatitude = currentLatitude
            startingLocationViewController.currentLongitude = currentLongitude
        }
    }
    
    override func loadView() {
        super.loadView()
        
        if currentLatitude == nil || currentLongitude == nil {
            currentLatitude = 37.549969
            currentLongitude = 126.941755
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: currentLatitude!, longitude: currentLongitude!, zoom: 9.0)
        mapView.camera = camera
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func initiateData() {
        DataManager.sharedInstance.dataModule = NetworkDataModule()
        DataManager.sharedInstance.currentWorldInfo = nil
        DataManager.sharedInstance.currentWorldIndex = -1
        
        DataManager.sharedInstance.msgInfoList.removeAll()
        DataManager.sharedInstance.nearWorldInfoList.removeAll()
        DataManager.sharedInstance.worldInfoList.removeAll()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        currentLatitude    = locValue.latitude
        currentLongitude   = locValue.longitude
    }
}

