//
//  FMInAppPurchaseTests.swift
//  FMInAppPurchaseTests
//
//  Created by Fantasy on 2017/9/26.
//  Copyright © 2017年 fantasy. All rights reserved.
//

import XCTest
@testable import FMInAppPurchase

class FMInAppPurchaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        
        FMInAppPurchase.default.addPayStatusHandle(handle: {
            [weak self] in
            self?.statusDispatch(status: $0.1)
            }, for: "Test")
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testIAP() {
        FMInAppPurchase.default.buy(productIdentifier: "")
        wait(for: [XCTestExpectation(description: "ddd")], timeout: 5.0)
    }
    
    func statusDispatch(status: FMInAppPurchase.PayStatus) {
        switch status {
        case let .hasFinishedPurchased(transactions):
            debugPrint("\(transactions)")
        default:
            XCTFail("test failed : \(status)")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
