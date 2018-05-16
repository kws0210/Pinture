//
//  WorldTableViewCell.swift
//  Pinture
//
//  Created by Team7 on 2018. 5. 16..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit

class WorldTableViewCell: UITableViewCell {
    
    
    @IBOutlet var btnLine: UIButton!
    @IBOutlet var msgLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func onTouchBtnLine(_ sender: UIButton) {
        let strStoreLineURL = "https://line.me/D"
        let message = "%5BPinture%5D%0A%EC%9A%B0%EB%A6%AC%EC%9D%98%20%ED%8A%B9%EB%B3%84%ED%95%9C%20%EC%9E%A5%EC%86%8C%2E%2E%2E%0A%EB%82%B4%EA%B0%80%20%EB%A7%8C%EB%93%A0%20AR%20World%EC%97%90%20%EC%B4%88%EB%8C%80%ED%95%A0%EA%B2%8C%0A%0A%0A%EB%A9%94%EC%84%B8%EC%A7%80%20%3A%20"
        guard let worldMessage = DataManager.sharedInstance.worldInfoList[sender.tag].message.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
        let worldSequence = DataManager.sharedInstance.worldInfoList[sender.tag].world_sequence
        let pintureURL = "pinture://share/\(worldSequence)/"
        let strLineURL = "line://msg/text/\(message)\(worldMessage)%0A\(pintureURL)%0A%0A%EC%84%A4%EC%B9%98%20URL%20%3A%20\(strStoreLineURL)"
        
        
        print(strLineURL)
        guard let openLineURL =  URL(string: strLineURL) else {return}
        if UIApplication.shared.canOpenURL(openLineURL) {
            UIApplication.shared.open(openLineURL)
        } else {
            guard let storeLineURL = URL(string: strStoreLineURL) else {return}
            UIApplication.shared.open(storeLineURL)
        }
    }
}
