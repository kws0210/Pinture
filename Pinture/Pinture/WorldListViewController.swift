//
//  WorldListViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 16..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit

class WorldListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var popupView: UIView!
    @IBOutlet var worldListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.popupView.layer.cornerRadius = 5;
        self.popupView.layer.shadowOpacity = 0.8;
        self.popupView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        worldListTableView.delegate = self
        worldListTableView.dataSource = self
        worldListTableView.tableFooterView = UIView()
        
       showAnimate()
    }

    
    @IBAction func onTouchBtnNewWorld(_ sender: Any) {
        removeAnimate()
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.sharedInstance.nearWorldInfoList.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell = self.worldListTableView.dequeueReusableCell(withIdentifier: "nearWorldListCell", for: indexPath as IndexPath) as! WorldTableViewCell
        
        // set the text from the data model
        cell.msgLabel.text = DataManager.sharedInstance.nearWorldInfoList[indexPath.row].message
        cell.timeLabel.text = DataManager.sharedInstance.nearWorldInfoList[indexPath.row].time
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DataManager.sharedInstance.currentWorldIndex = indexPath.row
        
        removeAnimate()
    }
    
    @IBAction func onTouchBtnExit(_ sender: Any) {
        self.parent?.dismiss(animated: true, completion: {})
    }
    
    
    func showAnimate()
    {
        self.view.alpha = 0.5
        self.popupView.transform = CGAffineTransform(scaleX: 1.0, y: 0.4)
        UIView.animate(withDuration: 0.25, animations: {
            self.popupView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.view.alpha = 1
        });
    }
    
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.popupView.transform = CGAffineTransform(scaleX: 1.0, y: 0.4)
            self.view.alpha = 0.5
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.view.removeFromSuperview()
            }
        });
    }

}
