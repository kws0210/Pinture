//
//  MapViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 4. 19..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    @objc let locationManager = CLLocationManager()
    var currentLatitude, currentLongitude : CLLocationDegrees?
    var inputMessageViewController : InputMessageViewController?
    
    @objc var marker = [GMSMarker]()
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet var btnStart: UIButton!
    @IBOutlet weak var worldListTableView: UITableView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var defaultTableView: UIView!
    
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
        
        worldListTableView.tableFooterView = UIView()
        btnStart.layer.cornerRadius = btnStart.bounds.size.width/2;
        btnStart.layer.masksToBounds = true;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let inputMessageVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inputMessage") as! InputMessageViewController
        self.addChildViewController(inputMessageVc)
        inputMessageVc.view.frame = self.view.frame
        self.inputMessageViewController = inputMessageVc
        
        self.initiateData()
        self.initiateWorldInfoList()
        DataManager.sharedInstance.messageModified = false
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
        
        worldListTableView.delegate = nil
        worldListTableView.dataSource = nil
    }
    
    func initiateWorldInfoList() {
        self.activityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        getUserInfo {
            if DataManager.sharedInstance.userWorldSequenceList.count == 0 {
                self.worldListTableView.backgroundView = self.defaultTableView
                self.worldListTableView.delegate = self
                self.worldListTableView.dataSource = self
                self.worldListTableView.reloadData()
                self.activityIndicatorView.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                self.checkOpenParam()
            } else {
                getWorldInfoList(completionHandler: {
                    
                    DataManager.sharedInstance.worldInfoList = DataManager.sharedInstance.worldInfoList.reversed()
                    
                    self.mapView.clear()
                    for mark in self.marker {
                        mark.map = nil
                    }
                    
                    for worldInfo in DataManager.sharedInstance.worldInfoList {
                        
                        // Creates a marker in the center of the map.
                        let tempMarker = GMSMarker()
                        
                        tempMarker.position = CLLocationCoordinate2D(latitude: worldInfo.latitude, longitude: worldInfo.longitude)
                        tempMarker.title = worldInfo.message
                        tempMarker.snippet = worldInfo.time
                        tempMarker.map = self.mapView
                        self.marker.append(tempMarker)
                        
                    }
                    
                    self.worldListTableView.backgroundView = self.defaultTableView
                    self.worldListTableView.delegate = self
                    self.worldListTableView.dataSource = self
                    self.worldListTableView.reloadData()
                    self.activityIndicatorView.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    self.checkOpenParam()
                })
            }
        }
        
    }
    
    func checkOpenParam() {
        
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
    
    func showAddWorldAlertView(worldSequence : Int) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        let alert = UIAlertController(title: "", message: "공유받은 월드를 저장하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "예", style: UIAlertActionStyle.default, handler: { action in
            if action.style == .default{
                self.activityIndicatorView.startAnimating()
                UIApplication.shared.beginIgnoringInteractionEvents()
                
                addWorldInfo(worldSequece : worldSequence, completionHandler: {
                    appDelegate.openParam = 0
                    self.initiateData()
                    self.initiateWorldInfoList()
                    self.activityIndicatorView.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "아니요", style: UIAlertActionStyle.cancel, handler: { action in
            if action.style == .cancel{
                appDelegate.openParam = 0
            }
        }))
        self.present(alert, animated: true, completion: {
            alert.view.superview?.isUserInteractionEnabled = true
        })
    }
    
    func showDeleteAlertView(index : Int) {
        let alert = UIAlertController(title: "", message: "\'\(DataManager.sharedInstance.worldInfoList[index].message)\'월드를 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "예", style: UIAlertActionStyle.default, handler: { action in
            if action.style == .default{
                self.activityIndicatorView.startAnimating()
                UIApplication.shared.beginIgnoringInteractionEvents()
                deleteWorldInfo(index: index, completionHandler: {
                    self.initiateData()
                    self.initiateWorldInfoList()
                    self.activityIndicatorView.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "아니요", style: UIAlertActionStyle.cancel, handler: { action in
            if action.style == .cancel{
                
            }
        }))
        self.present(alert, animated: true, completion: {
            alert.view.superview?.isUserInteractionEnabled = true
        })
    }
    
    func showEnterAlertView(index : Int) {
        let alert = UIAlertController(title: "", message: "\'\(DataManager.sharedInstance.worldInfoList[index].message)\'월드에 입장하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "예", style: UIAlertActionStyle.default, handler: { action in
            if action.style == .default{
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "StartingLocationViewController") as! StartingLocationViewController
                let world = DataManager.sharedInstance.worldInfoList[index]
                DataManager.sharedInstance.nearWorldInfoList.append(world)
                DataManager.sharedInstance.dataModule.currentWorldSequence = world.world_sequence
                vc.enterWorldIndex = index
                self.present(vc, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "아니요", style: UIAlertActionStyle.cancel, handler: { action in
            if action.style == .cancel{
                
            }
        }))
        self.present(alert, animated: true, completion: {
            alert.view.superview?.isUserInteractionEnabled = true
        })
    }
    
    func showInputMessagePopup(index : Int) {
        let inputMessageVc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inputMessage") as! InputMessageViewController
        self.addChildViewController(inputMessageVc)
        inputMessageVc.view.frame = self.view.frame
        self.inputMessageViewController = inputMessageVc
        self.view.addSubview(self.inputMessageViewController!.view)
        self.inputMessageViewController!.didMove(toParentViewController: self)
        self.inputMessageViewController?.msgInput.text = DataManager.sharedInstance.worldInfoList[index].message
    }
    
    @objc func alertControllerBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        currentLatitude    = locValue.latitude
        currentLongitude   = locValue.longitude
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if DataManager.sharedInstance.worldInfoList.count == 0 {
            worldListTableView.separatorStyle = .none
            worldListTableView.backgroundView?.isHidden = false
        } else {
            worldListTableView.separatorStyle = .singleLine
            worldListTableView.backgroundView?.isHidden = true
        }
        
        return DataManager.sharedInstance.worldInfoList.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell = self.worldListTableView.dequeueReusableCell(withIdentifier: "worldListCell", for: indexPath as IndexPath) as! WorldTableViewCell
        
        // set the text from the data model
        cell.msgLabel.text = DataManager.sharedInstance.worldInfoList[indexPath.row].message
        cell.timeLabel.text = DataManager.sharedInstance.worldInfoList[indexPath.row].time
        cell.btnLine.tag = indexPath.row
        cell.selectionStyle = .none
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let world = DataManager.sharedInstance.worldInfoList[indexPath.row]
        let diffLatitude = abs(Int(Double(world.latitude) * 1000) - Int(Double(self.currentLatitude!) * 1000))
        let diffLongitude = abs(Int(Double(world.longitude) * 1000) - Int(Double(self.currentLongitude!) * 1000))
        
        self.mapView?.animate(toLocation: CLLocationCoordinate2D(latitude: DataManager.sharedInstance.worldInfoList[indexPath.row].latitude, longitude: DataManager.sharedInstance.worldInfoList[indexPath.row].longitude ))
        self.mapView.animate(toZoom: 16)
        
        if diffLatitude < 5 && diffLongitude < 5 {
            checkWorldExist(worldSequence: world.world_sequence, posCompletion: {
                self.showEnterAlertView(index: indexPath.row)
            }, negCompletion: {
                self.showMessageAlertView(message: "삭제된 월드입니다.", completionHandler: {
                    self.initiateWorldInfoList()
                })
            })
        } else {
            self.showMessageAlertView(message: "100m 내에 접근 시\n\'\(world.message)\'월드에 입장할 수 있습니다.", completionHandler: {})
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let del = UITableViewRowAction(style: .normal , title: "삭제") { action, index in
            self.showDeleteAlertView(index: indexPath.row)
        }
        
        let edit = UITableViewRowAction(style: .destructive, title: "수정") { action, index in
            self.showInputMessagePopup(index: indexPath.row)
            DataManager.sharedInstance.currentWorldIndex = indexPath.row
        }
        edit.backgroundColor = UIColor.lightGray
        
        
        del.backgroundColor = UIColor.red
        
        return [del, edit]
    }
    
    
    
    override func viewDidLayoutSubviews() {
        
        guard let inputMessageViewController = self.inputMessageViewController else { return }
        if DataManager.sharedInstance.messageModified
            && !self.view.subviews.contains(inputMessageViewController.view) {
            modifyWorldInfo(index: DataManager.sharedInstance.currentWorldIndex, message: inputMessageViewController.msgInput.text!,  completionHandler: {
                self.initiateData()
                self.initiateWorldInfoList()
                DataManager.sharedInstance.messageModified = false
            })
        }
    }
}

