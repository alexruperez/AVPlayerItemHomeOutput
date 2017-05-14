//
//  ViewController.swift
//  AVPlayerItemHomeOutput
//
//  Created by Alex Rupérez on 14/5/17.
//  Copyright © 2017 alexruperez. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import AVPlayerItemHomeOutput

class ViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let sample = URL(string: "https://raw.githubusercontent.com/bower-media-samples/big-buck-bunny-1080p-30s/master/video.mp4")!
        let asset = AVAsset(url: sample)
        let playerItem = AVPlayerItem(asset: asset)
        let homeOutput = AVPlayerItemHomeOutput(playerItem)
        homeOutput.setDelegate(self, queue: nil)
        playerItem.add(homeOutput)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = AVPlayer(playerItem: playerItem)
        present(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }

}

extension ViewController: AVPlayerItemOutputPullDelegate {

    func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {

    }

    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {

    }
    
}
