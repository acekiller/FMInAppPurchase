//
//  ViewController.swift
//  FMInAppPurchase
//
//  Created by Fantasy on 2017/9/26.
//  Copyright © 2017年 fantasy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FMInAppPurchase.default.addPayStatusHandle(handle: {
            [weak self] in
            self?.statusDispatch(status: $0.1)
            }, for: "ViewController")
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FMInAppPurchase.default.hasTransaction {
            debugPrint("has product")
        } else {
            FMInAppPurchase.default.buy(productIdentifier: "092606")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func statusDispatch(status: FMInAppPurchase.PayStatus) {
        switch status {
        case let .hasFinishedPurchased(transactions):
            debugPrint("\(transactions)")
        default:
            debugPrint("test failed : \(status)")
        }
    }
}

