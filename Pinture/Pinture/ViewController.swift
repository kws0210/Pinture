//
//  ViewController.swift
//  Pinture
//
//  Created by 고원섭 on 2018. 4. 19..
//  Copyright © 2018년 Sogang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var testLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onTouchBtnLogin(_ sender: Any) {
        print("login button clicked")
        testLabel.text = "Login button clicked"
    }
    
}

