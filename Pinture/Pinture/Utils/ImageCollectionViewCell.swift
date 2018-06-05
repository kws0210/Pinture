//
//  ImageCollectionViewCell.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 10..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    func configurecell(image: UIImage){
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
}
