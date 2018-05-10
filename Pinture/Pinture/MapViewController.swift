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
    
}

