//
//  AVPlayerItemHomeOutput.swift
//  AVPlayerItemHomeOutput
//
//  Created by Alex Rupérez on 14/5/17.
//  Copyright © 2017 alexruperez. All rights reserved.
//

import AVFoundation

/// The AVPlayerItemHomeOutput lets you coordinate the output of content associated with your HomeKit lightbulbs.
public class AVPlayerItemHomeOutput: AVPlayerItemVideoOutput {

    fileprivate var userDelegate: AVPlayerItemOutputPullDelegate?
    fileprivate var userDelegateQueue: DispatchQueue?
    fileprivate var displayLink: CADisplayLink!

    private let playerItem: AVPlayerItem
    private let colors: UInt

    /**
    	Returns an instance of AVPlayerItemHomeOutput, initialized with the specified AVPlayerItem and the number of desired colors.
    	- parameter playerItem: The AVPlayerItem to extract the color information.
    	- parameter colors: The number of colors to extract and send to your HomeKit lightbulbs.
    	- returns: An instance of AVPlayerItemHomeOutput.
     */
    public init(_ playerItem: AVPlayerItem, colors: UInt = 3) {
        self.playerItem = playerItem
        self.colors = colors
        super.init(pixelBufferAttributes: nil)
        super.setDelegate(self, queue: DispatchQueue(label: "AVPlayerItemHomeOutput (\(playerItem))", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink.add(to: .current, forMode: .defaultRunLoopMode)
        displayLink.isPaused = true
    }

    public override func setDelegate(_ delegate: AVPlayerItemOutputPullDelegate?, queue delegateQueue: DispatchQueue? = nil) {
        userDelegate = delegate
        userDelegateQueue = delegateQueue
    }

    func displayLinkCallback() {
        delegateQueue?.async {
            let outputItemTime = self.itemTime(forHostTime: self.displayLink.timestamp + self.displayLink.duration)
            if self.hasNewPixelBuffer(forItemTime: outputItemTime), let pixelBuffer = self.copyPixelBuffer(forItemTime: outputItemTime, itemTimeForDisplay: nil) {
                HomeManager.shared.send(pixelBuffer, colors: self.colors)
            }
        }
    }

}

extension AVPlayerItemHomeOutput: AVPlayerItemOutputPullDelegate {

    public func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
        displayLink.isPaused = false
        if let delegate = userDelegate {
            if let delegateQueue = userDelegateQueue {
                delegateQueue.async {
                    delegate.outputMediaDataWillChange?(sender)
                }
            } else {
                delegate.outputMediaDataWillChange?(sender)
            }
        }
    }

    public func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
        requestNotificationOfMediaDataChange(withAdvanceInterval: 0.03)
        if let delegate = userDelegate {
            if let delegateQueue = userDelegateQueue {
                delegateQueue.async {
                    delegate.outputSequenceWasFlushed?(output)
                }
            } else {
                delegate.outputSequenceWasFlushed?(output)
            }
        }
    }
    
}
