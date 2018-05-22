//
//  InputMessageViewController
//  Pinture
//
//  Created by Team7 on 2018. 5. 17..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit

class InputMessageViewController: UIViewController {
    
    @IBOutlet var msgInput: UITextField!
    @IBOutlet var popupView: UIView!

    @IBAction func onTouchBtnOk(_ sender: Any) {
        
        DataManager.sharedInstance.messageModified = true
        DataManager.sharedInstance.currentWorldInfo?.message = msgInput.text!
        
        removeAnimate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.sharedInstance.viewState = .InputMessage
        showAnimate()
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
        if touch.view != popupView {
            removeAnimate()
        }
    }
}
