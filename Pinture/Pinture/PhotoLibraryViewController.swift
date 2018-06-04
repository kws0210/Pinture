//
//  PhotoLibraryViewController.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 10..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit
import Photos
import ARKit

class PhotoLibraryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var popupView: UIView!
    
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<AnyObject>!
    var assetThumbnailSize: CGSize!
    @IBOutlet var btnTitle: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.popupView.layer.cornerRadius = 5;
        self.popupView.layer.shadowOpacity = 0.8;
        self.popupView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        if let layout = self.collectionView!.collectionViewLayout as? UICollectionViewFlowLayout{
            let cellSize = layout.itemSize
            
            self.assetThumbnailSize = CGSize(width: cellSize.width, height: cellSize.height)
            checkPhotoLibraryPermission()
        }
        if DataManager.sharedInstance.isVideoMode {
            btnTitle.setTitle("동영상", for: .normal)
        } else {
            btnTitle.setTitle("사진", for: .normal)
        }
        
        DataManager.sharedInstance.viewState = .photoLibrary
        showAnimate()
    }
    
    @IBAction func onTouchBtnTitle(_ sender: Any) {
        if DataManager.sharedInstance.isVideoMode {
            DataManager.sharedInstance.isVideoMode = false
            DataManager.sharedInstance.pickedVideoUrl = nil
            btnTitle.setTitle("사진", for: .normal)
        } else {
            DataManager.sharedInstance.isVideoMode = true
            btnTitle.setTitle("동영상", for: .normal)
        }
        
        self.loadPhotoLibrary()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if touch.view != popupView {
            removeAnimate()
        }
    }
    
    func checkPhotoLibraryPermission() {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.loadPhotoLibrary()
                } else {}
            })
        } else if photos == .authorized {
            self.loadPhotoLibrary()
        } else if photos == .denied || photos == .restricted {
            self.showPermissionDeniedAlertView()
            print("denied")
        }
    }
    
    func showPermissionDeniedAlertView() {
        let alert = UIAlertController(title: "사진첩 권한", message: "사진첩 권한 허용이 설정되어 있지 않습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true)
    }
    
    func loadPhotoLibrary() {
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false) ]
        
        if DataManager.sharedInstance.isVideoMode {
            self.photosAsset = PHAsset.fetchAssets(with: .video, options: fetchOptions) as! PHFetchResult<AnyObject>
        } else {
            self.photosAsset = PHAsset.fetchAssets(with: .image, options: fetchOptions) as! PHFetchResult<AnyObject>
        }
        
        self.collectionView!.reloadData()
        
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        var count: Int = 0
        
        if(self.photosAsset != nil){
            count = self.photosAsset.count
        }
        return count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cameraCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
        
        //Modify the cell
        let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.version = PHImageRequestOptionsVersion.current
        PHImageManager.default().requestImage(for: asset, targetSize: self.assetThumbnailSize, contentMode: .aspectFill, options: options, resultHandler: {(result, info)in
            if result != nil {
                cell.configurecell(image: result!)
            } else {
                print("result nil")
            }
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
        
        
        
        if DataManager.sharedInstance.isVideoMode {
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (videoAsset, audioMix, info) in
                if videoAsset is AVComposition {
                    let videoAsset = videoAsset as! AVComposition
                    
                    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    let documentsDirectory: NSString? = paths.first as NSString?
                    if documentsDirectory != nil {
                        let random = Int(arc4random() % 1000)
                        let pathToAppend = String(format: "mergeSlowMoVideo-%d.mov", random)
                        let myPathDocs = documentsDirectory!.strings(byAppendingPaths: [pathToAppend])
                        let myPath = myPathDocs.first
                        if myPath != nil {
                            let url = URL(fileURLWithPath: myPath!)
                            let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
                            if exporter != nil {
                                exporter!.outputURL = url
                                exporter!.outputFileType = AVFileType.mov
                                exporter!.shouldOptimizeForNetworkUse = true
                                exporter!.exportAsynchronously(completionHandler: {
                                    DispatchQueue.main.async {
                                        let url = exporter!.outputURL
                                        if url != nil {
                                            DataManager.sharedInstance.pickedVideoUrl = url
                                            
                                            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width:1920, height:1280) , contentMode: .aspectFill, options: nil, resultHandler: { (result , info) in
                                                
                                                DataManager.sharedInstance.pickedImage = result as! UIImage
                                                DataManager.sharedInstance.pickedExtensionName = "mov"
                                                
                                                self.removeAnimate()
                                            })
                                        }
                                    }
                                })
                            }
                        }
                    }
                } else if videoAsset is AVAsset {
                    let videoAsset = videoAsset as! AVURLAsset
                    DataManager.sharedInstance.pickedVideoUrl = videoAsset.url
                    
                    PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width:1280, height:1280) , contentMode: .aspectFill, options: nil, resultHandler: { (result , info) in
                        
                        DataManager.sharedInstance.pickedImage = result as! UIImage
                        DataManager.sharedInstance.pickedExtensionName = videoAsset.url.pathExtension
                        
                        self.removeAnimate()
                    })
                }
            })
        } else {
            let options = PHImageRequestOptions()
            options.version = PHImageRequestOptionsVersion.current
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width:1920, height:1280) , contentMode: .aspectFill, options: nil, resultHandler: { (result , info) in
                
                asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (input, _) in
                    let url = input?.fullSizeImageURL
                    
                    DataManager.sharedInstance.pickedExtensionName = url!.pathExtension
                    DataManager.sharedInstance.pickedImage = result as! UIImage
                    self.removeAnimate()
                    
                }
            })
        }
    }
    
    
    @IBAction func onTouchBtnClose(_ sender: Any) {
        DataManager.sharedInstance.pickedImage = nil
        removeAnimate()
    }
    
    
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(translationX: 0, y: self.popupView.frame.height)
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(translationX: 0, y: 0)
        });
    }
    
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(translationX: 0, y: self.popupView.frame.height)
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.view.removeFromSuperview()
            }
        });
    }
}

