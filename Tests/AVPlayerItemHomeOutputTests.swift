//
//  AVPlayerItemHomeOutputTests.swift
//  AVPlayerItemHomeOutput
//
//  Created by Alex Rupérez on 14/5/17.
//  Copyright © 2017 alexruperez. All rights reserved.
//

import XCTest
@testable import AVPlayerItemHomeOutput

class MockHomeManager: HomeManager {
    override var hasPrimaryHome: Bool {
        return super.hasPrimaryHome || true
    }
}

class AVPlayerItemHomeOutputTests: XCTestCase {

    var output: AVPlayerItemHomeOutput?
    var homeManager: HomeManager?
    
    override func setUp() {
        super.setUp()
        let sample = URL(string: "https://raw.githubusercontent.com/bower-media-samples/big-buck-bunny-1080p-30s/master/video.mp4")!
        let asset = AVAsset(url: sample)
        let playerItem = AVPlayerItem(asset: asset)
        output = AVPlayerItemHomeOutput(playerItem)
        homeManager = MockHomeManager()
    }
    
    override func tearDown() {
        homeManager = nil
        output = nil
        super.tearDown()
    }
    
    func testOutputDelegateWithDispatchQueue() {
        let dispatchQueue = DispatchQueue(label: "TestDelegateDispatchQueue")
        if let output = output {
            output.setDelegate(self, queue: dispatchQueue)
            output.outputSequenceWasFlushed(output)
            output.outputMediaDataWillChange(output)
        }
    }

    func testOutputDelegateWithoutDispatchQueue() {
        if let output = output {
            output.setDelegate(self)
            output.outputSequenceWasFlushed(output)
            output.outputMediaDataWillChange(output)
        }
    }

    func testSendColors() {
        homeManager?.send([.red, .green, .blue])
    }

    func testSendPixelBuffer() {
        if let lenna = UIImage(named: "Lenna", in: Bundle(for: AVPlayerItemHomeOutputTests.self), compatibleWith: nil) {
            if let cgLenna = lenna.cgImage {
                UIGraphicsBeginImageContext(lenna.size)
                if #available(iOS 9.0, *), let currentContext = UIGraphicsGetCurrentContext() {
                    let ciContext = CIContext(cgContext: currentContext, options: nil)
                    var lennaPixelBuffer: CVPixelBuffer? = nil
                    var pixelBufferPool: CVPixelBufferPool? = nil
                    let sourcePixelBufferOptions: NSDictionary = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                                                  kCVPixelBufferWidthKey: lenna.size.width,
                                                                  kCVPixelBufferHeightKey: lenna.size.height,
                                                                  kCVPixelFormatOpenGLESCompatibility: true,
                                                                  kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()]
                    CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, sourcePixelBufferOptions, &pixelBufferPool)
                    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool!, &lennaPixelBuffer)
                    ciContext.render(CIImage(cgImage: cgLenna), to: lennaPixelBuffer!)
                    homeManager?.send(lennaPixelBuffer!, colors: 3)
                }
                UIGraphicsEndImageContext()
            }
        }
    }

    func testUpdateCharacteristic() {
        homeManager?.update(HMCharacteristic(), floatValue: 50)
        XCTAssertGreaterThan(homeManager!.updating.count, 0)
    }

    func testPerformanceTopColors() {
        self.measure {
            if let colors = self.homeManager?.top([.orange: 4, .red: 10, .black: 2, .green: 8, .white: 3, .blue: 6, .gray: 5], number: 3) {
                XCTAssertTrue(colors.contains(.red))
                XCTAssertTrue(colors.contains(.green))
                XCTAssertTrue(colors.contains(.blue))
                XCTAssertFalse(colors.contains(.orange))
                XCTAssertFalse(colors.contains(.black))
                XCTAssertFalse(colors.contains(.white))
                XCTAssertFalse(colors.contains(.gray))
            }
        }
    }

    func testPerformanceDiffColors() {
        self.measure {
            if let colors = self.homeManager?.diff([[0, 0, 0, 255], [192, 192, 192, 255], [32, 32, 32, 255], [255, 255, 255, 255], [64, 64, 64, 255]], number: 3) {
                let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                let lightGray = UIColor(red: 32/255, green: 32/255, blue: 32/255, alpha: 1)
                let gray = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1)
                let darkGray = UIColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1)
                let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
                XCTAssertTrue(colors.contains(white))
                XCTAssertTrue(colors.contains(lightGray))
                XCTAssertTrue(colors.contains(gray))
                XCTAssertFalse(colors.contains(darkGray))
                XCTAssertFalse(colors.contains(black))
            }
        }
    }

}

extension AVPlayerItemHomeOutputTests: AVPlayerItemOutputPullDelegate {

    func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
        XCTAssert(true)
    }

    func outputSequenceWasFlushed(_ sender: AVPlayerItemOutput) {
        XCTAssert(true)
    }

}
