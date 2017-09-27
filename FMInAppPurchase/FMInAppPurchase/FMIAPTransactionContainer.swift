//
//  FMIAPTransactionContainer.swift
//  FMInAppPurchase
//
//  Created by Fantasy on 2017/9/26.
//  Copyright © 2017年 fantasy. All rights reserved.
//

import UIKit
import StoreKit

public class FMIAPTransactionContainer {
    fileprivate let lock = NSLock()
    fileprivate var transactions = [SKPaymentTransaction]()
    fileprivate var verifyHandle: (String)->Void = {_ in}
    fileprivate var payFailedHandle: (SKPaymentTransaction)->Void = {_ in}
    fileprivate var payDeferredHandle: (SKPaymentTransaction)->Void = {_ in}
    fileprivate var restoredHandle: (SKPaymentTransaction)->Void = {_ in}
}

fileprivate extension FMIAPTransactionContainer {
    
    func containsTransaction(transaction: SKPaymentTransaction) -> Bool {
        return (transactions.filter {$0.payment.productIdentifier == transaction.payment.productIdentifier}.isEmpty)
    }
    
    func appendTransaction(transaction: SKPaymentTransaction) {
        lock.lock()
        defer {
            lock.unlock()
        }
        transactions.append(transaction)
    }
    
    func removeTransaction(transaction: SKPaymentTransaction) {
        guard let index = transactions.index(of: transaction) else {
            return
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        transactions.remove(at: index)
    }
    
    func removeTransactions(transactions: [SKPaymentTransaction]) {
        lock.lock()
        defer {
            lock.unlock()
        }
        for trans in transactions {
            if let index = self.transactions.index(of: trans) {
                self.transactions.remove(at: index)
            }
        }
    }
    
    func updateTransactionCache(transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .deferred:
            removeTransaction(transaction: transaction)
        case .purchased:
            appendTransaction(transaction: transaction)
        case .purchasing:
            appendTransaction(transaction: transaction)
        case .failed:
            removeTransaction(transaction: transaction)
        case .restored:
            removeTransaction(transaction: transaction)
        }
    }
    
    func finishTransactions(transactionIdentifier:[String]) -> [SKPaymentTransaction] {
        let verifiedTransactions = transactions.filter {
            .purchased == $0.transactionState
            }
            .filter {
                transactionIdentifier.contains($0.transactionIdentifier!)
        }
        verifiedTransactions.forEach {
            SKPaymentQueue.default().finishTransaction($0)
        }
        
        removeTransactions(transactions: verifiedTransactions)
        return verifiedTransactions
    }
}

fileprivate extension FMIAPTransactionContainer {
    func transtractionStateDispatch(transaction: SKPaymentTransaction) {
        if .purchased == transaction.transactionState {
            guard let receipt = receiptData else {
                return
            }
            verifyHandle(receipt)
            return
        }
        if .failed == transaction.transactionState {
            payFailedHandle(transaction)
            return
        }
        
        if .deferred == transaction.transactionState {
            payDeferredHandle(transaction)
        }
        
        if .restored == transaction.transactionState {
            restoredHandle(transaction)
        }
        
    }
}

public extension FMIAPTransactionContainer {
    var receiptData: String? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        return (try? Data(contentsOf: url))?.base64EncodedString()
    }
    
}

public extension FMIAPTransactionContainer {
    /**
     * :params: handle 传入的值String，是用于服务器端进行验证的base64编码数据
     */
    func setverifyHandle(handle: @escaping (String)->Void) {
        verifyHandle = handle
    }
    
    func setPayFailedHandle(handle: @escaping (SKPaymentTransaction)->Void) {
        payFailedHandle = handle
    }
    
    func setPayDeferredHandle(handle: @escaping (SKPaymentTransaction)->Void) {
        payDeferredHandle = handle
    }
    
    func setRestoredHandle(handle: @escaping (SKPaymentTransaction)->Void) {
        restoredHandle = handle
    }
}

public extension FMIAPTransactionContainer {
    
    /**
     *
     */
    public func updateTransaction(transaction: SKPaymentTransaction) {
        updateTransactionCache(transaction: transaction)
        transtractionStateDispatch(transaction: transaction)
    }
    
    public func updateTransactions(transaction: [SKPaymentTransaction]) {
        transactions.forEach {
            [weak self] in
            self?.updateTransaction(transaction: $0)
        }
    }
    
    /**
     * :params: transaction_ids 苹果服务器验证成功返回的交易相关ID
     */
    public func updateTransactionToVerified(transaction_ids: [String]) -> [SKPaymentTransaction] {
        return finishTransactions(transactionIdentifier: transaction_ids)
    }
}

public extension FMIAPTransactionContainer {
    public func transaction(transactionIdentifier: String, state: SKPaymentTransactionState = .purchased) -> SKPaymentTransaction? {
        return transactions.filter{state == $0.transactionState}
            .filter {$0.transactionIdentifier != nil}
            .filter { $0.transactionIdentifier! == transactionIdentifier}
            .first
    }
    
    public func transaction(productIdentifier: String, state: SKPaymentTransactionState = .purchased) -> SKPaymentTransaction? {
        return transactions.filter{state == $0.transactionState}
            .filter {$0.payment.productIdentifier == productIdentifier}
            .first
    }
    
    public var firstTransaction: SKPaymentTransaction? {
        return transactions.first
    }
    
    public var firstPurchasedTransaction: SKPaymentTransaction? {
        return transactions.filter({.purchased == $0.transactionState}).first
    }
}
