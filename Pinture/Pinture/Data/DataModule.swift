//
//  DataModule.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 15..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import FirebaseStorage

class DataModule {
    
    func getMsgData( contentsName : String, completionHandler: (() -> Void)!) {
        self.getSpecificData(contentsName, completionHandler: completionHandler)
    }
    
    func getNearWorldData(latitude: CLLocationDegrees!, longitude: CLLocationDegrees!, completionHandler: (() -> Void)!) {
        self.getNearWorldSpecificData(latitude: latitude, longitude: longitude, completionHandler: completionHandler)
    }
    
    
    func readMsgData(_ jsonString : String, completionHandler: (() -> Void)!) {
        let data = jsonString.data(using: String.Encoding.utf8)
        if let msgInfoList = try! JSONSerialization.jsonObject(with:  data!, options: JSONSerialization.ReadingOptions()) as? [Any] {
            
            DataManager.sharedInstance.msgInfoList.removeAll()
            
            var isMsgInWorld = false
            DataManager.sharedInstance.cntNetworkingMsgURL = 0
            for msgInfo in msgInfoList {
                if let msg = msgInfo as? [String: Any] {
                    
                    let strSequence = msg["sequence"] as? String
                    let strWorldSequence = msg["world_sequence"] as? String
                    let strLatitude = msg["latitude"] as? String
                    let strLongitude = msg["longitude"] as? String
                    let strPosition_x = msg["position_x"] as? String
                    let strPosition_y = msg["position_y"] as? String
                    let strPosition_z = msg["position_z"] as? String
                    let strEulerAngles_x = msg["eulerAngles_x"] as? String
                    let strEulerAngles_y = msg["eulerAngles_y"] as? String
                    let strEulerAngles_z = msg["eulerAngles_z"] as? String
                    let strScale_x = msg["scale_x"] as? String
                    let strScale_y = msg["scale_y"] as? String
                    let strScale_z = msg["scale_z"] as? String
                    let strExtensionName = msg["extension_name"] as? String
                    let strContentsType = msg["contents_type"] as? String
                    let strContentsUrl = msg["contents_url"] as? String
                    
                    let world_sequence = Int(strWorldSequence!)
                    if world_sequence! == DataManager.sharedInstance.currentWorldInfo!.world_sequence {
                        DataManager.sharedInstance.cntNetworkingMsgURL += 1
                        isMsgInWorld = true
                        
                        let storage = Storage.storage()
                        let storageRef = storage.reference(forURL: strContentsUrl!)
                        storageRef.downloadURL(completion: { (contentsUrl, error) in
                            if error != nil {
                                print(error)
                            } else {
                                let sequence = Int(strSequence!)
                                let latitude = Double(strLatitude!) as! CLLocationDegrees
                                let longitude = Double(strLongitude!) as! CLLocationDegrees
                                let position_x = Float(strPosition_x!)
                                let position_y = Float(strPosition_y!)
                                let position_z = Float(strPosition_z!)
                                let eulerAngles_x = Float(strEulerAngles_x!)
                                let eulerAngles_y = Float(strEulerAngles_y!)
                                let eulerAngles_z = Float(strEulerAngles_z!)
                                let scale_x = Float(strScale_x!)
                                let scale_y = Float(strScale_y!)
                                let scale_z = Float(strScale_z!)
                                let contentsType = Int(strContentsType!)
                                
                                // Do something with your image.
                                DataManager.sharedInstance.msgInfoList.append((sequence!, world_sequence!, latitude, longitude, position_x!, position_y!, position_z!, eulerAngles_x!, eulerAngles_y!, eulerAngles_z!, scale_x!, scale_y!, scale_z!, contentsType!, contentsUrl!, nil, nil, strExtensionName!, 0))
                                
                                DataManager.sharedInstance.cntNetworkingMsgURL -= 1
                                if DataManager.sharedInstance.cntNetworkingMsgURL == 0 {
                                    completionHandler()
                                    
                                }
                            }
                        })
                    }
                }
            }
            if !isMsgInWorld { completionHandler() }
        }
    }
    
    func readWorldData(_ jsonString : String, completionHandler: (() -> Void)!) {
        
        let data = jsonString.data(using: String.Encoding.utf8)
        if let worldInfoList = try! JSONSerialization.jsonObject(with:  data!, options: JSONSerialization.ReadingOptions()) as? [Any] {
            
            DataManager.sharedInstance.worldInfoList.removeAll()
            for worldInfo in worldInfoList {
                if let world = worldInfo as? [String: Any] {
                    
                    
                    let strWorldSequence = world["world_sequence"] as? String
                    let strLatitude = world["latitude"] as? String
                    let strLongitude = world["longitude"] as? String
                    let strImageUrl = world["imageUrl"] as? String
                    let message = world["message"] as? String
                    let time = world["time"] as? String
                    let world_sequence = Int(strWorldSequence!)
                    let latitude = Double(strLatitude!) as! CLLocationDegrees
                    let longitude = Double(strLongitude!) as! CLLocationDegrees
                    
                    
                    
                    // Do something with your image.
                    DataManager.sharedInstance.worldInfoList.append((world_sequence!, latitude, longitude, strImageUrl!, nil, message!, time!))
                    
                    
                    
                }
            }
            completionHandler()
        }
    }
    
    
    func addWorldData(worldSequence: Int, completionHandler : (()->Void)!) {
        self.addWorldNetworkData(worldSequence: worldSequence, completionHandler : completionHandler)
    }
    
    
    func uploadWorldData(viewController : ARWorldViewController, worldSequence: Int,
                         latitude: CLLocationDegrees, longitude: CLLocationDegrees, image: UIImage, message: String, time: String, completionHandler : (()->Void)!) {
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let fileName = String( worldSequence ) + ".jpg"
        
        // Create a reference to "(sequence).jpg"
        let imageRef = storageRef.child("hint/" + fileName)
        
        let uploadTask = imageRef.putData(UIImageJPEGRepresentation(image, 1.0)!, metadata: nil) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print(error)
            } else {
                uploadMsgInfo(viewController : viewController, completionHandler: {
                    let jsonString = formatWorldData(
                        world_sequence: worldSequence, latitude: latitude, longitude: longitude
                        , imageUrl: "gs://pinture-203616.appspot.com/hint/" + fileName, message: message, time: time)
                    
                    DataManager.sharedInstance.uploadingJSONList.append(jsonString)
                    self.saveSpecificData("worldInfoList")
                    DataManager.sharedInstance.uploadingJSONList.removeAll()
                    completionHandler()
                })
            }
        }
    }
    
    
    func uploadMsgData(viewController : ARWorldViewController, completionHandler : (()->Void)!) {
        DataManager.sharedInstance.cntUploadingMsgImage = 0
        DataManager.sharedInstance.cntDeletingMsgImage = 0
        
        for index in 0..<DataManager.sharedInstance.msgInfoList.count {
            let msgInfo = DataManager.sharedInstance.msgInfoList[index]
            
            if msgInfo.state == 1 {
                DataManager.sharedInstance.cntUploadingMsgImage += 1
                
                let storage = Storage.storage()
                let storageRef = storage.reference()
                
                //picture type
                if msgInfo.contentsType <= 10 {
                    let fileName = String( msgInfo.sequence ) + "." + msgInfo.extensionName!
                    let imageRef = storageRef.child("picture/" + fileName)
                    
                    let uploadTask = imageRef.putData(UIImageJPEGRepresentation(msgInfo.image!, 1.0)!, metadata: nil) { metadata, error in
                        if (error != nil) {
                            print(error)
                        } else {
                            let jsonString = formatMsgData(
                                sequence: msgInfo.sequence, world_sequence: msgInfo.world_sequence
                                ,latitude: msgInfo.latitude, longitude: msgInfo.longitude
                                , position_x: msgInfo.position_x, position_y: msgInfo.position_y, position_z: msgInfo.position_z
                                , eulerAngles_x: msgInfo.eulerAngles_x, eulerAngles_y: msgInfo.eulerAngles_y, eulerAngles_z: msgInfo.eulerAngles_z
                                , scale_x: msgInfo.scale_x, scale_y: msgInfo.scale_y, scale_z: msgInfo.scale_z
                                , extensionName: msgInfo.extensionName!
                                , contentsType: msgInfo.contentsType
                                , contentsUrl: "gs://pinture-203616.appspot.com/picture/" + fileName)
                            
                            DataManager.sharedInstance.uploadingJSONList.append(jsonString)
                            DataManager.sharedInstance.cntUploadingMsgImage -= 1
                            if DataManager.sharedInstance.cntUploadingMsgImage == 0 {
                                self.saveSpecificData("msgInfoList")
                                DataManager.sharedInstance.uploadingJSONList.removeAll()
                                
                                if DataManager.sharedInstance.cntDeletingMsgImage == 0 {
                                    completionHandler()
                                }
                            }
                        }
                    }
                    uploadTask.observe(.progress) { snapshot in
                        let percentComplete = 100 * Int(snapshot.progress!.completedUnitCount)
                            / Int(snapshot.progress!.totalUnitCount)
                        
                        viewController.updateCompletePercent(sequence : msgInfo.sequence, completionPercent : percentComplete)
                        
                    }
                    
                    uploadTask.observe(.success) { snapshot in
                        viewController.updateComplete(sequence : msgInfo.sequence)
                    }
                    
                //video type
                } else {
                    let fileName = String( msgInfo.sequence ) + "." + msgInfo.contentsUrl.pathExtension
                    let videoRef = storageRef.child("video/" + fileName)
                    
                    let path = NSTemporaryDirectory().appendingFormat( fileName)
                    let pathUrl = URL(fileURLWithPath: path)
                    let exportSession = AVAssetExportSession(asset: AVAsset(url:msgInfo.contentsUrl), presetName: AVAssetExportPresetHighestQuality)
                    exportSession?.outputURL = pathUrl
                    exportSession?.outputFileType = AVFileType.mov
                    exportSession?.exportAsynchronously {
                        do {
                            let videoData = try Data(contentsOf: pathUrl)
                            
                            DispatchQueue.main.async(execute: {() -> Void in
                                
                                let uploadTask = videoRef.putData(videoData, metadata: nil) { metadata, error in
                                    if (error != nil) {
                                        print(error)
                                    } else {
                                        let jsonString = formatMsgData(
                                            sequence: msgInfo.sequence, world_sequence: msgInfo.world_sequence
                                            ,latitude: msgInfo.latitude, longitude: msgInfo.longitude
                                            , position_x: msgInfo.position_x, position_y: msgInfo.position_y, position_z: msgInfo.position_z
                                            , eulerAngles_x: msgInfo.eulerAngles_x, eulerAngles_y: msgInfo.eulerAngles_y, eulerAngles_z: msgInfo.eulerAngles_z
                                            , scale_x: msgInfo.scale_x, scale_y: msgInfo.scale_y, scale_z: msgInfo.scale_z
                                            , extensionName: msgInfo.extensionName!
                                            , contentsType: msgInfo.contentsType
                                            , contentsUrl: "gs://pinture-203616.appspot.com/video/" + fileName)
                                        
                                        DataManager.sharedInstance.uploadingJSONList.append(jsonString)
                                        DataManager.sharedInstance.cntUploadingMsgImage -= 1
                                        if DataManager.sharedInstance.cntUploadingMsgImage == 0 {
                                            self.saveSpecificData("msgInfoList")
                                            DataManager.sharedInstance.uploadingJSONList.removeAll()
                                            
                                            if DataManager.sharedInstance.cntDeletingMsgImage == 0 {
                                                completionHandler()
                                            }
                                        }
                                    }
                                }
                                
                                uploadTask.observe(.progress) { snapshot in
                                    let percentComplete = 100 * Int(snapshot.progress!.completedUnitCount)
                                        / Int(snapshot.progress!.totalUnitCount)
                                    
                                    
                                    viewController.updateCompletePercent(sequence : msgInfo.sequence, completionPercent : percentComplete)
                                }
                                
                                uploadTask.observe(.success) { snapshot in
                                    viewController.updateComplete(sequence : msgInfo.sequence)
                                }
                                
                            })
                            
                            
                        } catch {
                            print(error)
                            return
                        }
                    }
                }
            } else if msgInfo.state == -1 {
                DataManager.sharedInstance.cntDeletingMsgImage += 1
                DataManager.sharedInstance.dataModule.deleteMsgData(contentsType: msgInfo.contentsType, sequence: msgInfo.sequence, extensionName: msgInfo.extensionName!, byWorldDelete: false, completionHandler: completionHandler)
            }
        }
    }
    
    
    
    func deleteWorldData( completionHandler: (() -> Void)!) {
        let worldSequence = DataManager.sharedInstance.currentWorldInfo?.world_sequence
        
        let storage = Storage.storage()
        
        // Create a root reference
        let storageRef = storage.reference()
        let fileName = String( worldSequence! ) + ".jpg"
        // Create a reference to "(sequence).jpg"
        let imageRef = storageRef.child("hint/" + fileName)
        let deleteWorldTask = imageRef.delete { (error) in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print(error)
                
            } else {
                if DataManager.sharedInstance.msgInfoList.count == 0 {
                    self.deleteWorldSpecificData(completionHandler: {
                        completionHandler()
                    })
                }
                
                DataManager.sharedInstance.cntDeletingMsgImage = 0
                for msgInfo in DataManager.sharedInstance.msgInfoList {
                    
                    DataManager.sharedInstance.cntDeletingMsgImage += 1
                    self.deleteMsgData(contentsType: msgInfo.contentsType, sequence: msgInfo.sequence, extensionName: msgInfo.extensionName!, byWorldDelete: true, completionHandler: {
                        self.deleteWorldSpecificData(completionHandler: {
                            completionHandler()
                        })
                    })
                }
                
                
            }
        }
    }
    
    func deleteMsgData( contentsType : Int, sequence : Int, extensionName : String, byWorldDelete : Bool, completionHandler: (() -> Void)!) {
        let storage = Storage.storage()
        let msgStorageRef = storage.reference()
        var msgFileName = String( sequence)
        
        let msgImageRef : StorageReference
        msgFileName = msgFileName + "." + extensionName
        if contentsType <= 10 {
            msgImageRef = msgStorageRef.child("picture/" + msgFileName)
        } else {
            msgImageRef = msgStorageRef.child("video/" + msgFileName)
        }
        
        msgImageRef.delete(completion: { (error) in
            if (error != nil) {
                print(error)
            } else {
                DataManager.sharedInstance.cntDeletingMsgImage -= 1
                DataManager.sharedInstance.deletingSequenceList.append(sequence)
                if DataManager.sharedInstance.cntDeletingMsgImage == 0 {
                    if byWorldDelete {
                        self.deleteMsgSpecificData(worldSequence: DataManager.sharedInstance.currentWorldInfo!.world_sequence, completionHandler:{
                            DataManager.sharedInstance.deletingSequenceList.removeAll()
                            if DataManager.sharedInstance.cntUploadingMsgImage == 0 {
                                completionHandler()
                            }
                        })
                    } else {
                        self.deleteMsgSpecificData(completionHandler: {
                            DataManager.sharedInstance.deletingSequenceList.removeAll()
                            if DataManager.sharedInstance.cntUploadingMsgImage == 0 {
                                completionHandler()
                            }
                        })
                    }
                }
            }
        })
    }
    
    func modifyWorldData( index : Int, completionHandler: (() -> Void)!) {
        self.modifyWorldSpecificData( index : index, completionHandler: completionHandler )
    }
    
    func checkWorldExist(worldSequence : Int, posCompletion : (() -> Void)!, negCompletion : (() -> Void)!) {}
    func register(uid : String, lineId : String, name : String) {}
    func getSpecificData(_ contentsName: String, completionHandler: (() -> Void)!) {}
    func getNearWorldSpecificData(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completionHandler: (() -> Void)!) {}
    func saveSpecificData(_ contentsName: String) {}
    func deleteWorldSpecificData( completionHandler: (() -> Void)!) {}
    func deleteMsgSpecificData( worldSequence : Int, completionHandler: (() -> Void)!) {}
    func deleteMsgSpecificData(completionHandler: (() -> Void)!) {}
    func modifyWorldSpecificData( index : Int, completionHandler: (() -> Void)!) {}
    func addWorldNetworkData(worldSequence: Int, completionHandler : (()->Void)!) {}
    func getUserWorldInfo(completionHandler : (()->Void)!) { completionHandler() }
}

