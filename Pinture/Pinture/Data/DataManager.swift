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

    
    var pickedImage : UIImage?
    var pickedExtensionName : String?
    
}
