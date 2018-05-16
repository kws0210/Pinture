//
//  ARWorldViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 10..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import Foundation
import GoogleMaps
import ARKit

final class DataManager {
    
    // Can't init is singleton
    private init() { }
    
    // MARK: Shared Instance
    
    static let sharedInstance = DataManager()
    
    // MARK: Local Variable
    
    var msgInfoList : [(
        sequence : Int
        , world_sequence : Int
        , latitude : CLLocationDegrees
        , longitude : CLLocationDegrees
        , position_x : Float
        , position_y : Float
        , position_z : Float
        , eulerAngles_x : Float
        , eulerAngles_y : Float
        , eulerAngles_z : Float
        , scale_x : Float
        , scale_y : Float
        , scale_z : Float
        , contentsType : Int
        , contentsUrl : URL
        , image : UIImage?
        , video : AVAsset?
        , extensionName : String?
        , state : Int)] = []
    
    var worldInfoList : [(
        world_sequence : Int
        , latitude : CLLocationDegrees
        , longitude : CLLocationDegrees
        , imageUrl : String
        , image : UIImage?
        , message : String
        , time : String)] = []
    
    var nearWorldInfoList : [(
        world_sequence : Int
        , latitude : CLLocationDegrees
        , longitude : CLLocationDegrees
        , imageUrl : String
        , image : UIImage?
        , message : String
        , time : String)] = []
    
    var currentWorldInfo : (
    world_sequence : Int
    , latitude : CLLocationDegrees
    , longitude : CLLocationDegrees
    , image : UIImage?
    , message : String
    , time : String)?
    
    var pickedImage : UIImage?
    var pickedVideoUrl : URL?
    var pickedExtensionName : String?
    var isVideoMode = false
    var cntNetworkingMsgURL = 0
    var cntUploadingMsgImage = 0
    var cntDownloadingMsgImage = 0
    var cntDeletingMsgImage = 0
    var currentWorldIndex = -1
    var messageModified = false
    var deletingSequenceList : [Int] = []
    var uploadingJSONList : [String] = []
    var userWorldSequenceList : [Int] = []
    
    enum viewStateEnum {
        case AR
        case photoLibrary
        case InputMessage
        case ImageDetail
        case ImageDetailSaved
    }
    
    var viewState = viewStateEnum.AR
    var dataModule = LocalDataModule()
}
