//
//  ARWorldViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 16..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import CoreLocation

final class LocalDataModule : DataModule{
    
    var currentSequence = -1
    var currentWorldSequence = -1
    
    override init() {
        super.init()
        if UserDefaults.standard.object(forKey: "sequence") == nil {
            self.currentSequence = 1
        } else {
            self.currentSequence = UserDefaults.standard.integer(forKey: "sequence")
        }
        
        if UserDefaults.standard.object(forKey: "world_sequence") == nil {
            self.currentWorldSequence = 1
            UserDefaults.standard.set(self.currentSequence, forKey: "world_sequence")
        } else {
            self.currentWorldSequence = UserDefaults.standard.integer(forKey: "world_sequence")
        }
        
    }
    
    override func saveSpecificData(_ contentsName: String) {
        let fileName = contentsName + ".txt"
        let dir = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let fileurl =  dir.appendingPathComponent(fileName)
        
        var jsonString = DataManager.sharedInstance.uploadingJSONList[0]
        for index in 1..<DataManager.sharedInstance.uploadingJSONList.count {
            jsonString += ", "
            jsonString += DataManager.sharedInstance.uploadingJSONList[index]
        }
        
        let str = ", " + jsonString
        
        if FileManager.default.fileExists(atPath: fileurl.path) {
            if let fileHandle = try? FileHandle(forUpdating: fileurl) {
                let readData = fileHandle.readDataToEndOfFile()
                let readStr = String(data: readData, encoding: String.Encoding.utf8)
                var finalStr = readStr!.substring(to: readStr!.index(before: readStr!.endIndex))
                finalStr = finalStr + str + "]"
                let data = finalStr.data(using: .utf8, allowLossyConversion: false)!
                
                try! data.write(to: fileurl, options: Data.WritingOptions.atomic)
                fileHandle.closeFile()
            }
        } else {
            let firstString = "[" + jsonString + "]"
            let firstData = firstString.data(using: .utf8, allowLossyConversion: false)
            try! firstData?.write(to: fileurl, options: Data.WritingOptions.atomic)
        }
        
        
        if fileName == "msgInfoList.txt" {
            UserDefaults.standard.set(currentSequence, forKey: "sequence")
        } else {
            let worldSequence = UserDefaults.standard.integer(forKey: "world_sequence") + 1
            UserDefaults.standard.set(worldSequence, forKey: "world_sequence")
        }
    }
    
    override func getSpecificData(_ contentsName : String, completionHandler: (() -> Void)!) {
        let fileName = contentsName + ".txt"
        let dir = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let fileurl =  dir.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileurl.path) {
            if let fileHandle = try? FileHandle(forUpdating: fileurl) {
                let data = fileHandle.readDataToEndOfFile()
                fileHandle.closeFile()
                
                let str = String(data: data, encoding: String.Encoding.utf8)
                
                if fileName == "msgInfoList.txt" {
                    readMsgData(str!, completionHandler : completionHandler)
                } else if fileName == "worldInfoList.txt" {
                    readWorldData(str!, completionHandler : completionHandler)
                }
            } else {
                print("Ooops! Something went wrong!")
            }
        } else {
            completionHandler()
        }
    }
    
    override func deleteWorldSpecificData( completionHandler: (() -> Void)!) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let fileurl =  dir.appendingPathComponent("worldInfoList.txt")
        
        if fileManager.fileExists(atPath: fileurl.path) {
            if let fileHandle = try? FileHandle(forUpdating: fileurl) {
                let data = fileHandle.readDataToEndOfFile()
                fileHandle.closeFile()
                
                if var worldInfoList = try! JSONSerialization.jsonObject(with:  data, options: JSONSerialization.ReadingOptions()) as? [Any] {
                    var indexShouldRemoved = -1
                    for index in 0...worldInfoList.count-1 {
                        if let world = worldInfoList[index] as? [String: Any] {
                            let strWorldSequence = world["world_sequence"] as? String
                            
                            if Int(strWorldSequence!) == DataManager.sharedInstance.currentWorldInfo?.world_sequence {
                                indexShouldRemoved = index
                            }
                        }
                    }
                    guard indexShouldRemoved != -1 else { return }
                    worldInfoList.remove(at: indexShouldRemoved)
                    
                    do {
                        try fileManager.removeItem(at: fileurl)
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                    
                    if worldInfoList.count != 0 {
                        if let objectData = try? JSONSerialization.data(withJSONObject: worldInfoList, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                            try! objectData.write(to: fileurl, options: Data.WritingOptions.atomic)
                        }
                    }
                    completionHandler()
                }
                
            } else {
                print("Ooops! Something went wrong!")
            }
        }
    }
    
    override func deleteMsgSpecificData( worldSequence : Int, completionHandler: (() -> Void)!) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let fileurl =  dir.appendingPathComponent("msgInfoList.txt")
        
        if fileManager.fileExists(atPath: fileurl.path) {
            if let fileHandle = try? FileHandle(forUpdating: fileurl) {
                let data = fileHandle.readDataToEndOfFile()
                fileHandle.closeFile()
                
                if var msgInfoList = try! JSONSerialization.jsonObject(with:  data, options: JSONSerialization.ReadingOptions()) as? [Any] {
                    var newMsgInfoList : [Any] = []
                    for index in 0..<msgInfoList.count {
                        if let msgInfo = msgInfoList[index] as? [String: Any] {
                            let strWorldSequence = msgInfo["world_sequence"] as? String
                            
                            if Int(strWorldSequence!) != worldSequence {
                                newMsgInfoList.append(msgInfo)
                            }
                        }
                    }
                    
                    
                    do {
                        try fileManager.removeItem(at: fileurl)
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                    
                    if newMsgInfoList.count != 0 {
                        if let objectData = try? JSONSerialization.data(withJSONObject: newMsgInfoList, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                            try! objectData.write(to: fileurl, options: Data.WritingOptions.atomic)
                            completionHandler()
                        }
                    } else {
                        print("msg all removed")
                        completionHandler()
                    }
                    
                }
                
            } else {
                print("Ooops! Something went wrong!")
            }
        }
    }
    
    override func deleteMsgSpecificData( completionHandler: (() -> Void)!) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let fileurl =  dir.appendingPathComponent("msgInfoList.txt")
        
        if fileManager.fileExists(atPath: fileurl.path) {
            if let fileHandle = try? FileHandle(forUpdating: fileurl) {
                let data = fileHandle.readDataToEndOfFile()
                fileHandle.closeFile()
                
                if var msgInfoList = try! JSONSerialization.jsonObject(with:  data, options: JSONSerialization.ReadingOptions()) as? [Any] {
                    var newMsgInfoList : [Any] = []
                    for index in 0...msgInfoList.count-1 {
                        if let msgInfo = msgInfoList[index] as? [String: Any] {
                            
                            guard let strSequence = msgInfo["sequence"] as? String else { return }
                            guard let sequence = Int(strSequence) else { return }
                            
                            if !DataManager.sharedInstance.deletingSequenceList.contains( sequence ) {
                                newMsgInfoList.append(msgInfo)
                            }
                        }
                    }
                    print(newMsgInfoList)
                    
                    
                    do {
                        try fileManager.removeItem(at: fileurl)
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                    
                    print( "remain msgInfo count : ", newMsgInfoList.count )
                    if newMsgInfoList.count != 0 {
                        if let objectData = try? JSONSerialization.data(withJSONObject: newMsgInfoList, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                            try! objectData.write(to: fileurl, options: Data.WritingOptions.atomic)
                            completionHandler()
                        }
                    } else {
                        print("msg all removed")
                        completionHandler()
                    }
                    
                }
                
            } else {
                print("Ooops! Something went wrong!")
            }
        }
    }
    
    override func modifyWorldSpecificData( index : Int, completionHandler: (() -> Void)!) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
        let fileurl =  dir.appendingPathComponent("worldInfoList.txt")
        
        if fileManager.fileExists(atPath: fileurl.path) {
            if let fileHandle = try? FileHandle(forUpdating: fileurl) {
                let data = fileHandle.readDataToEndOfFile()
                fileHandle.closeFile()
                
                if var worldInfoList = try! JSONSerialization.jsonObject(with:  data, options: JSONSerialization.ReadingOptions()) as? [Any] {
                    var newWorldInfoList : [Any] = []
                    for idx in 0...worldInfoList.count-1 {
                        if var world = worldInfoList[idx] as? [String: Any] {
                            let strWorldSequence = world["world_sequence"] as? String
                            
                            if Int(strWorldSequence!) == DataManager.sharedInstance.worldInfoList[index].world_sequence {
                                world["message"] = DataManager.sharedInstance.currentWorldInfo?.message
                            }
                            newWorldInfoList.append(world)
                        }
                    }
                    
                    do {
                        try fileManager.removeItem(at: fileurl)
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                    
                    if newWorldInfoList.count != 0 {
                        if let objectData = try? JSONSerialization.data(withJSONObject: newWorldInfoList, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                            try! objectData.write(to: fileurl, options: Data.WritingOptions.atomic)
                        }
                    }
                    completionHandler()
                }
                
            } else {
                print("Ooops! Something went wrong!")
            }
        }
    }
}
