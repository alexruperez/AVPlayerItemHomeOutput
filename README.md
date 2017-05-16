# AVPlayerItemHomeOutput

[![Twitter](https://img.shields.io/badge/contact-@alexruperez-0FABFF.svg?style=flat)](http://twitter.com/alexruperez)
[![Version](https://img.shields.io/cocoapods/v/AVPlayerItemHomeOutput.svg?style=flat)](http://cocoapods.org/pods/AVPlayerItemHomeOutput)
[![License](https://img.shields.io/cocoapods/l/AVPlayerItemHomeOutput.svg?style=flat)](http://cocoapods.org/pods/AVPlayerItemHomeOutput)
[![Platform](https://img.shields.io/cocoapods/p/AVPlayerItemHomeOutput.svg?style=flat)](http://cocoapods.org/pods/AVPlayerItemHomeOutput)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Build Status](https://travis-ci.org/alexruperez/AVPlayerItemHomeOutput.svg?branch=master)](https://travis-ci.org/alexruperez/AVPlayerItemHomeOutput)
[![Code Coverage](https://codecov.io/gh/alexruperez/AVPlayerItemHomeOutput/branch/master/graph/badge.svg)](https://codecov.io/gh/alexruperez/AVPlayerItemHomeOutput)
[![codebeat badge](https://codebeat.co/badges/f724bedf-023f-45a0-b854-d2e864561f7a)](https://codebeat.co/projects/github-com-alexruperez-avplayeritemhomeoutput-master)

![*AVPlayerItemHomeOutput*](https://raw.githubusercontent.com/alexruperez/AVPlayerItemHomeOutput/master/AVPlayerItemHomeOutput.jpg)

The *AVPlayerItemHomeOutput* lets you coordinate the output of content associated with your [*HomeKit*](https://www.apple.com/shop/accessories/all-accessories/homekit) lightbulbs.

In other words, becomes [*#Ambilight*](https://en.wikipedia.org/wiki/Ambilight). 😀

Works with all [*HomeKit*](https://developer.apple.com/homekit) (and [*HomeBridge*](https://github.com/nfarina/homebridge)) compatible lightbulbs.

![*AVPlayerItemHomeOutput*](https://raw.githubusercontent.com/alexruperez/AVPlayerItemHomeOutput/master/AVPlayerItemHomeOutput.gif)

## Installation

AVPlayerItemHomeOutput is available through [*CocoaPods*](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AVPlayerItemHomeOutput'
```

#### Or you can install it with [*Carthage*](https://github.com/Carthage/Carthage):

```ogdl
github "alexruperez/AVPlayerItemHomeOutput"
```

#### Or install it with [*Swift Package Manager*](https://swift.org/package-manager/):

```swift
dependencies: [
    .Package(url: "https://github.com/alexruperez/AVPlayerItemHomeOutput.git")
]
```

## Usage

```swift
let sample = URL(string: "https://raw.githubusercontent.com/bower-media-samples/big-buck-bunny-1080p-30s/master/video.mp4")!
let asset = AVAsset(url: sample)
let playerItem = AVPlayerItem(asset: asset)
let homeOutput = AVPlayerItemHomeOutput(playerItem) // Only create your instance...
homeOutput.setDelegate(self, queue: nil) // Optional AVPlayerItemOutputPullDelegate.
playerItem.add(homeOutput) // ...and add it to your AVPlayerItem!
let playerViewController = AVPlayerViewController()
playerViewController.player = AVPlayer(playerItem: playerItem)
present(playerViewController, animated: true) {
        playerViewController.player?.play()
}
```

#### Don't forget:

Add *NSHomeKitUsageDescription* key to your *Info.plist* to specify the use of HomeKit in your app.

## Etc.

* Contributions are very welcome.
* Attribution is appreciated (let's spread the word!), but not mandatory.

## Authors

[alexruperez](https://github.com/alexruperez), contact@alexruperez.com

## License

*AVPlayerItemHomeOutput* is available under the MIT license. See the LICENSE file for more info.
