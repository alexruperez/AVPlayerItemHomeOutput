//
//  ExampleUITests.swift
//  AVPlayerItemHomeOutput
//
//  Created by Alex Rupérez on 14/5/17.
//  Copyright © 2017 alexruperez. All rights reserved.
//

import XCTest

class ExampleUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        if #available(iOS 9.0, *) {
            XCUIApplication().launch()
        }
    }
    
    func testVideoPlayback() {}
    
}
