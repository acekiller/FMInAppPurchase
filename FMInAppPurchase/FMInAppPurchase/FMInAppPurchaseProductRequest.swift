//
//  FMInAppPurchaseProductRequest.swift
//  FMInAppPurchase
//
//  Created by Fantasy on 2017/9/26.
//  Copyright © 2017年 fantasy. All rights reserved.
//

import Foundation
import StoreKit

internal class FMInAppPurchaseProductRequest: NSObject {
    fileprivate let productIdentifiers: [String]
    fileprivate let requestProductHandle: (FMInAppPurchaseProductRequest,[SKProduct],[String])->Void
    fileprivate let failedHandle: (FMInAppPurchaseProductRequest,Error)->Void
    
    init(productIdentifiers: [String],
         dataHandle:@escaping (FMInAppPurchaseProductRequest,[SKProduct],[String])->Void,
         failed:@escaping (FMInAppPurchaseProductRequest,Error)->Void) {
        requestProductHandle = dataHandle
        self.productIdentifiers = productIdentifiers
        self.failedHandle = failed
    }
}

internal extension FMInAppPurchaseProductRequest {
    internal func start() {
        let set = Set(productIdentifiers)
        let request = SKProductsRequest(productIdentifiers: set)
        request.delegate = self
        request.start()
    }
}

extension FMInAppPurchaseProductRequest: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        requestProductHandle(self,response.products,response.invalidProductIdentifiers)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        debugPrint("\(#function)")
        failedHandle(self, error)
    }
    
    func requestDidFinish(_ request: SKRequest) {
    }
}
