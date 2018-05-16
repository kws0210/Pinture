//
//  NetworkDataModule.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 16..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseDatabase

final class NetworkDataModule : DataModule{
    
    var currentSequence = -1
    var lastWorldSequence = -1
    var currentWorldSequence = -1
    let ref = Database.database().reference()
    
    override init() {
        super.init()
        
        ref.child("var").observe(.value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            self.currentSequence = value?["sequence"] as! Int
            self.currentWorldSequence = value?["world_sequence"] as! Int
            self.lastWorldSequence = self.currentWorldSequence
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    override func register(uid: String, lineId: String, name: String) {
        self.ref.child("users").child(lineId).child("uid").setValue(uid)
        self.ref.child("users").child(lineId).child("name").setValue(name)
    }
    
    override func checkWorldExist(worldSequence : Int, posCompletion : (() -> Void)!, negCompletion : (() -> Void)!) {
        return ref.child("worldInfo").observeSingleEvent(of: .value) { snapshot in
            
            if snapshot.hasChild(String(worldSequence)){
                posCompletion()
            }else{
                negCompletion()
            }
        }
    }
    
    override func getUserWorldInfo( completionHandler: (() -> Void)!) {
        guard let lineId = UserDefaults.standard.string(forKey: "lineId") else {return}
        
        self.ref.child("users").child(lineId).child("world").observeSingleEvent(of: .value) { snapshot in
            DataManager.sharedInstance.userWorldSequenceList.removeAll()
            DataManager.sharedInstance.worldInfoList.removeAll()
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                DataManager.sharedInstance.userWorldSequenceList.append(Int(snap.key)!)
                
            }
            completionHandler()
        }
    }
    
    override func saveSpecificData(_ contentsName: String) {
        
        guard let lineId = UserDefaults.standard.string(forKey: "lineId") else {return}
        
        if contentsName == "worldInfoList" {
            let childUpdates = ["/var/world_sequence": self.lastWorldSequence+1]
            ref.updateChildValues(childUpdates)
        } else {
            let childUpdates = ["/var/sequence": self.currentSequence]
            ref.updateChildValues(childUpdates)
        }
        
        for jsonString in DataManager.sharedInstance.uploadingJSONList {
            if let data = jsonString.data(using: String.Encoding.utf8) {
                do {
                    let decoder = JSONDecoder()
                    let jsonDictionary = try decoder.decode(Dictionary<String, String>.self, from: data)
                    
                    if contentsName == "msgInfoList" {
                        let tableName   = "msgInfo"
                        let key         = String(self.currentWorldSequence)
                        let childKey = jsonDictionary["sequence"]!
                        
                        self.ref.child(tableName).child(key).child(childKey).setValue(jsonDictionary)
                    } else if contentsName == "worldInfoList" {
                        let tableName   = "worldInfo"
                        let key         = String(self.currentWorldSequence)
                        let childKey    = "shared"
                        
                        self.ref.child(tableName).child(key).setValue(jsonDictionary)
                        self.ref.child(tableName).child(key).child(childKey).child(lineId).setValue("1")
                        self.ref.child("users").child(lineId).child("world").child(key).setValue("1")
                    }
                    
                    
                } catch {
                    print(error)
                }
            }
        }
    }
    
    override func getSpecificData(_ contentsName : String, completionHandler: (() -> Void)!) {
        
        guard let lineId = UserDefaults.standard.string(forKey: "lineId") else {return}
        if contentsName == "msgInfoList" {
            let worldSequence = String(DataManager.sharedInstance.currentWorldInfo!.world_sequence)
            
            ref.child("msgInfo").child(worldSequence).observeSingleEvent(of: .value) { snapshot in
                var dictList : [Any] = []
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    let dict = snap.value as! [String: AnyObject]
                    dictList.append(dict)
                }
                
                if dictList.count != 0 {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dictList, options: .prettyPrinted)
                        let str = String(data: jsonData, encoding: String.Encoding.utf8)
                        
                        self.readMsgData(str!, completionHandler : completionHandler)
                        
                    } catch {
                        print(error.localizedDescription)
                    }
                } else {
                    completionHandler()
                }
            }
        } else if contentsName == "worldInfoList" {
            var worldList : [Any] = []
            
            var getCount = 0
            for worldSequence in DataManager.sharedInstance.userWorldSequenceList {
                getCount += 1
                ref.child("worldInfo").child(String(worldSequence)).observeSingleEvent(of: .value) { snapshot in
                    let dict = snapshot.value as! [String: AnyObject]
                    worldList.append(dict)
                    
                    getCount -= 1
                    if getCount == 0 {
                        if worldList.count != 0 {
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: worldList, options: .prettyPrinted)
                                let str = String(data: jsonData, encoding: String.Encoding.utf8)
                                
                                self.readWorldData(str!, completionHandler : completionHandler)
                                
                            } catch {
                                print(error.localizedDescription)
                            }
                        } else {
                            completionHandler()
                        }
                    }
                }
            }
        }
    }
    
    override func deleteWorldSpecificData( completionHandler: (() -> Void)!) {
        
        guard let currentWorldInfo = DataManager.sharedInstance.currentWorldInfo else {return}
        let worldSequence = String(currentWorldInfo.world_sequence)
        
        ref.child("worldInfo").child(worldSequence).child("shared").observeSingleEvent(of: .value) { snapshot in
            let users = snapshot.value as! [String : String]
            var delCount = 0
            for user in users {
                delCount += 1
                self.ref.child("users").child(user.key).child("world").child(worldSequence).removeValue { (error, ref) in
                    delCount -= 1
                    if delCount == 0 {
                        self.ref.child("worldInfo").child(worldSequence).removeValue { (error, ref) in
                            completionHandler()
                        }
                    }
                }
            }
        }
    }
    
    override func deleteMsgSpecificData( worldSequence : Int, completionHandler: (() -> Void)!) {
        let sequence = String(worldSequence)
        ref.child("msgInfo").child(sequence).removeValue { (error, ref) in
            completionHandler()
        }
    }
    
    override func deleteMsgSpecificData( completionHandler: (() -> Void)!) {
        guard let currentWorldInfo = DataManager.sharedInstance.currentWorldInfo else {return}
        let worldSequence = String(currentWorldInfo.world_sequence)
        
        DataManager.sharedInstance.cntNetworkingMsgURL = 0
        for deletingSequence in DataManager.sharedInstance.deletingSequenceList {
            let sequence = String(deletingSequence)
            DataManager.sharedInstance.cntNetworkingMsgURL += 1
            ref.child("msgInfo").child(worldSequence).child(sequence).removeValue { (error, ref) in
                DataManager.sharedInstance.cntNetworkingMsgURL -= 1
                if DataManager.sharedInstance.cntNetworkingMsgURL == 0 {
                    completionHandler()
                }
            }
        }
    }
    
    override func modifyWorldSpecificData( index : Int, completionHandler: (() -> Void)!) {
        let worldSequence = String(DataManager.sharedInstance.worldInfoList[index].world_sequence)
        let message = DataManager.sharedInstance.currentWorldInfo?.message
        
        ref.child("worldInfo").child(worldSequence).child("message").setValue(message)
        completionHandler()
    }
    
    override func addWorldNetworkData(worldSequence: Int, completionHandler : (()->Void)!) {
        guard let lineId = UserDefaults.standard.string(forKey: "lineId") else {return}
        
        ref.child("worldInfo").child(String(worldSequence)).child("shared").child(lineId).setValue("1")
        ref.child("users").child(lineId).child("world").child(String(worldSequence)).setValue("1")
        
        completionHandler()
    }
}

