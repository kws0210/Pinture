//
//  LoginViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 28..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import Firebase
import LineSDK

class LoginViewController: UIViewController, LineSDKLoginDelegate {
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnLoginWeb: UIButton!
    var uid : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.btnLogin.layer.cornerRadius = 5;
        self.btnLogin.layer.shadowOpacity = 0.3;
        self.btnLogin.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)

        // Use Firebase library to configure APIs
        Auth.auth().signInAnonymously() { (user, error) in
            self.uid = user!.user.uid
            
            LineSDKLogin.sharedInstance().delegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.string(forKey: "accessToken") == nil {
            btnLogin.isHidden = false
            btnLoginWeb.isHidden = false
            print("not yet login")
        } else {
            self.goToMapViewController()
        }
    }
    
    @IBAction func onTouchBtnLogin(_ sender: Any) {
        if LineSDKLogin.sharedInstance().canLoginWithLineApp() {
            LineSDKLogin.sharedInstance().start()
        } else {
            LineSDKLogin.sharedInstance().startWebLogin(withSafariViewController: true)
        }
    }
    
    @IBAction func onTouchBtnLoginWeb(_ sender: Any) {
        LineSDKLogin.sharedInstance().startWebLogin(withSafariViewController: true)
    }
    
    func didLogin(_ login: LineSDKLogin, credential: LineSDKCredential?, profile: LineSDKProfile?, error: Error?) {
        if error != nil {
            print(error)
        } else {
            let accessToken = credential?.accessToken?.accessToken
            let userId = profile?.userID
            let displayName = profile?.displayName
            let statusMessage = profile?.statusMessage
            let pictureUrl = profile?.pictureURL
            
            var pictureUrlString : String?
            
            if pictureUrl != nil {
                pictureUrlString = pictureUrl?.absoluteString
            }
            
            //upload [userInfo] to server
            
            DataManager.sharedInstance.dataModule.register( uid : self.uid!, lineId : userId!, name : displayName!)
            UserDefaults.standard.set(userId, forKey: "lineId")
            UserDefaults.standard.set(accessToken, forKey: "accessToken")
            
            self.goToMapViewController()
        }
    }
    
    func goToMapViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MapViewController")
        self.present(vc, animated: true, completion: nil)
    }
}

