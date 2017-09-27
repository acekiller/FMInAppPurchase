//
//  FMInAppPurchase.swift
//  FMInAppPurchase
//
//  Created by Fantasy on 2017/9/26.
//  Copyright © 2017年 fantasy. All rights reserved.
//

import UIKit
import StoreKit

public class FMInAppPurchase: NSObject {
    
    public enum PayStatus {
        case notAllow(String)
        case repeatOrder(String)
        case noProduct(String)   //(productIdentifier)
        case productRequesFailed(Error) //(获取SKProduct失败)
        case payFailed(SKPaymentTransaction)
        case payDeferred(SKPaymentTransaction)
        case payRestored(SKPaymentTransaction)
        case hasFinishedPurchased([SKPaymentTransaction])
    }
    
    fileprivate var verifyHandle: (String)->Void = {_ in}
    fileprivate var payStatusHandles = [String:(String,PayStatus)->Void]()
    fileprivate var productRequests = [FMInAppPurchaseProductRequest]()
    fileprivate let transactionContainer = FMIAPTransactionContainer()
    fileprivate let requestArrayLock = NSLock()
    
    public static let `default` = FMInAppPurchase()
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
}

fileprivate extension FMInAppPurchase {
    
    func sendPayStatus(_ status: PayStatus) {
        self.payStatusHandles.forEach {
            $0.value($0.key, status)
        }
    }
    
    func bindTransactionContainerHandle() {
        transactionContainer.setverifyHandle {
            [weak self] in
            self?.verifyHandle($0)
        }
        
        transactionContainer.setPayFailedHandle {
            [weak self] in
            self?.sendPayStatus(PayStatus.payFailed($0))
        }
        
        transactionContainer.setPayDeferredHandle {
            [weak self] in
            self?.sendPayStatus(PayStatus.payDeferred($0))
        }
        
        transactionContainer.setRestoredHandle {
            [weak self] in
            self?.sendPayStatus(PayStatus.payRestored($0))
        }
    }
}

public extension FMInAppPurchase {
    /**
     * :params: handle 传入的值String，是用于服务器端进行验证的base64编码数据
     */
    public func setverifyHandle(handle: @escaping (String)->Void) {
        verifyHandle = handle
    }
    
    /**
     * :params: handle 传入的值String：为方法配置的key值回传。
     */

    public func addPayStatusHandle(handle: @escaping (String,PayStatus)->Void, for key:String) {
        payStatusHandles[key] = handle
    }
    
    public func removePayStatusHandle(for key:String) {
        payStatusHandles.removeValue(forKey: key)
    }
}

public extension FMInAppPurchase {
    public var hasTransaction: Bool {
        return firstTransaction != nil ? true : false
    }
    
    public var firstTransaction: SKPaymentTransaction? {
        return transactionContainer.firstTransaction()
    }
}

/**
 *  IAP购买与获取已上架的IAP产品列表
 */
public extension FMInAppPurchase {
    
    /**
     *  购买，此方法将先验证商品的合法性，在进行支付操作。
     */
    public func buy(productIdentifier:String) {
        guard SKPaymentQueue.canMakePayments() else {
            self.sendPayStatus(PayStatus.notAllow(productIdentifier))
            return
        }
        
        loadProducts(with: [productIdentifier],
                     dataHandle: {
                        [weak self] in
                        guard let product = $0.0.filter({$0.productIdentifier == productIdentifier}).first else {
                            self?.sendPayStatus(PayStatus.noProduct(productIdentifier))
                            return
                        }
                        self?.buy(product: product)
            },
                     failed: {
                        [weak self] in
                        self?.sendPayStatus(PayStatus.productRequesFailed($0))
        })
    }
    
    /**
     *  购买
     */
    public func buy(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            self.sendPayStatus(PayStatus.notAllow(product.productIdentifier))
            return
        }
        
        if transactionContainer.transaction(productIdentifier: product.productIdentifier) != nil {
            self.sendPayStatus(PayStatus.repeatOrder(product.productIdentifier))
            return
        }
        
        SKPaymentQueue.default().add(SKPayment(product: product))
    }
    
    /*获取已上架的IAP产品列表*/
    public func loadProducts(with productIdentifiers: [String],
                             dataHandle:@escaping ([SKProduct],[String])->Void,
                             invalidHandle: @escaping ([String])->Void = {_ in},
                             failed:@escaping (Error)->Void) {
        let request = FMInAppPurchaseProductRequest(productIdentifiers: productIdentifiers,
                                                    dataHandle:
            {
                [weak self] in
                dataHandle($0.1,$0.2)
                self?.removeRequest($0.0)
        },failed: {
            [weak self] in
            failed($0.1)
            self?.removeRequest($0.0)
            
        })
        productRequests.append(request)
        request.start()
        
    }
    
    func finishTransactions(transaction_ids: [String]) {
        let transactions = transactionContainer.updateTransactionToVerified(transaction_ids: transaction_ids)
        self.sendPayStatus(PayStatus.hasFinishedPurchased(transactions));
    }
}

extension FMInAppPurchase {
    func addRequest(_ request: FMInAppPurchaseProductRequest) {
        requestArrayLock.lock()
        defer {
            requestArrayLock.unlock()
        }
        productRequests.append(request)
    }
    func removeRequest(_ request: FMInAppPurchaseProductRequest) {
        requestArrayLock.lock()
        defer {
            requestArrayLock.unlock()
        }
        guard let index = productRequests.index(of: request) else {
            return
        }
        productRequests.remove(at: index)
    }
}

/*
 *支付流程代理方法处理
 */
extension FMInAppPurchase: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactionContainer.updateTransactions(transaction: transactions)
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        debugPrint("\(#function) : \(queue.transactions)")
    }
}
