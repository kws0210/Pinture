//
//  ImageDetailViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 6. 4..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


class ImageDetailViewController: UIViewController {
    var videoUrl : URL?
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var popupView: UIView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelTime: UILabel!
    
    @IBAction func onTouchBtnSave(_ sender: Any) {
        if videoUrl == nil {
            UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil);
            self.removeAnimate()
        } else {
            self.saveVideo()
        }
    }
    
    @IBAction func onTouchBtnDelete(_ sender: Any) {
        DataManager.sharedInstance.viewState = .ImageDetailSaved
        self.removeAnimate()
    }
    
    @IBAction func onTouchBtnClose(_ sender: Any) {
        self.removeAnimate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.sharedInstance.viewState = .ImageDetail
        self.showAnimate()
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
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if touch.view != self.popupView {
            self.removeAnimate()
        }
    }
    
    func saveVideo() {
        DispatchQueue.main.async {
            self.activityIndicatorView.startAnimating()
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        DispatchQueue.global(qos: .background).async {
            if let url = self.videoUrl {
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                let filePath="\(documentsPath)/tempFile." + url.pathExtension;
                
                if url.isFileURL {
                    
                    let pathUrl = URL(fileURLWithPath: filePath)
                    let exportSession = AVAssetExportSession(asset: AVAsset(url:url), presetName: AVAssetExportPresetHighestQuality)
                    exportSession?.outputURL = pathUrl
                    exportSession?.outputFileType = AVFileType.mov
                    exportSession?.exportAsynchronously {
                        do {
                            guard let data = try NSData(contentsOfFile: pathUrl.path) else { return }
                            self.setVideoToCameraRoll(data : data, filePath : filePath)
                        } catch let error {print(error)}
                    }
                } else {
                    guard let urlData = NSData(contentsOf: url) else {return}
                    self.setVideoToCameraRoll(data : urlData, filePath : filePath)
                }
            }
        }
    }
    
    func setVideoToCameraRoll(data : NSData, filePath : String) {
        DispatchQueue.main.async {
            data.write(toFile: filePath, atomically: true)
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
            }) { completed, error in
                if completed {
                    do {
                        if FileManager.default.fileExists(atPath: filePath) {
                            try FileManager.default.removeItem(at: URL(fileURLWithPath: filePath))
                        }
                    } catch let error {
                        print(error.localizedDescription)
                    }
                    DispatchQueue.main.async {
                        self.activityIndicatorView.stopAnimating()
                        UIApplication.shared.endIgnoringInteractionEvents()
                        self.removeAnimate()
                        
                    }
                } else {
                    print(error)
                }
            }
        }
    }
}
