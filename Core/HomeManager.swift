//
//  HomeManager.swift
//  AVPlayerItemHomeOutput
//
//  Created by Alex Rupérez on 14/5/17.
//  Copyright © 2017 alexruperez. All rights reserved.
//

import HomeKit

class HomeManager {

    static let shared = HomeManager()
    private let manager = HMHomeManager()
    private var primaryHome: HMHome? {
        return manager.primaryHome
    }
    private var hasPrimaryHome: Bool {
        return primaryHome != nil
    }
    private var updating = [HMCharacteristic: Bool]()

    func send(_ pixelBuffer: CVPixelBuffer, colors: UInt) {
        guard hasPrimaryHome && colors > 0 else {
            return
        }
        var samples = [[UInt8]]()
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = image.extent
        for i in 0..<colors {
            for j in 0..<colors {
                var bitmap = [UInt8](repeating: 0, count: 4)
                let context = CIContext()
                let inputExtent = CIVector(x: extent.origin.x/CGFloat(colors*i), y: extent.origin.y/CGFloat(colors*j), z: extent.size.width/CGFloat(colors), w: extent.size.height/CGFloat(colors))
                let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: image, kCIInputExtentKey: inputExtent])!
                let outputImage = filter.outputImage!
                let outputExtent = outputImage.extent
                assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
                context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
                samples.append(bitmap)
            }
        }
        send(diff(samples, number: Int(colors)))
    }

    func send(_ colors: [UIColor]) {
        guard let lightbulbServices = primaryHome?.servicesWithTypes([HMServiceTypeLightbulb]) else {
            return
        }
        var colorIndex = 0
        for lightbulbService in lightbulbServices {
            var HSBA = [CGFloat](repeating: 0, count: 4)
            colors[colorIndex % colors.count].getHue(&HSBA[0], saturation: &HSBA[1], brightness: &HSBA[2], alpha: &HSBA[3])
            colorIndex += 1
            for characteristic in lightbulbService.characteristics {
                if updating[characteristic] == nil {
                    updating[characteristic] = false
                }
                guard updating[characteristic] == false else {
                    break
                }
                if characteristic.characteristicType == HMCharacteristicTypePowerState, characteristic.value as? Bool != true {
                    updating[characteristic] = true
                    characteristic.writeValue(true, completionHandler: { error in
                        if error != nil {
                            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
                                self?.updating[characteristic] = false
                            })
                        } else {
                            self.updating[characteristic] = false
                        }
                    })
                }
                if characteristic.characteristicType == HMCharacteristicTypeBrightness, characteristic.value as? CGFloat != HSBA[2] {
                    let value = NSNumber(value: Int(Float(HSBA[2]) * (characteristic.metadata?.maximumValue?.floatValue ?? 100)))
                    updating[characteristic] = true
                    characteristic.writeValue(value, completionHandler: { error in
                        if error != nil {
                            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
                                self?.updating[characteristic] = false
                            })
                        } else {
                            self.updating[characteristic] = false
                        }
                    })
                }
                if characteristic.characteristicType == HMCharacteristicTypeSaturation, characteristic.value as? CGFloat != HSBA[1] {
                    let value = NSNumber(value: Int(Float(HSBA[1]) * (characteristic.metadata?.maximumValue?.floatValue ?? 100)))
                    updating[characteristic] = true
                    characteristic.writeValue(value, completionHandler: { error in
                        if error != nil {
                            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
                                self?.updating[characteristic] = false
                            })
                        } else {
                            self.updating[characteristic] = false
                        }
                    })
                }
                if characteristic.characteristicType == HMCharacteristicTypeHue, characteristic.value as? CGFloat != HSBA[0] {
                    let value = NSNumber(value: Int(Float(HSBA[0]) * (characteristic.metadata?.maximumValue?.floatValue ?? 100)))
                    updating[characteristic] = true
                    characteristic.writeValue(value, completionHandler: { error in
                        if error != nil {
                            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
                                self?.updating[characteristic] = false
                            })
                        } else {
                            self.updating[characteristic] = false
                        }
                    })
                }
            }
        }
    }

}

private extension HomeManager {

    func top(_ colors: [UIColor: CGFloat], number: Int) -> [UIColor] {
        return colors.sorted(by: { $0.1 > $1.1 }).prefix(number).map({ $0.0 })
    }

    func diff(_ colors: [[UInt8]], number: Int) -> [UIColor] {
        var diffColors = [UIColor: CGFloat]()
        for components in colors {
            for diffComponents in colors {
                guard components != diffComponents else {
                    break
                }
                let diffRed = abs(CGFloat(components[0]) - CGFloat(diffComponents[0]))
                let diffGreen = abs(CGFloat(components[1]) - CGFloat(diffComponents[1]))
                let diffBlue = abs(CGFloat(components[2]) - CGFloat(diffComponents[2]))
                let color = UIColor(red: CGFloat(components[0]) / 255.0, green: CGFloat(components[1]) / 255.0, blue: CGFloat(components[2]) / 255.0, alpha: CGFloat(components[3]) / 255.0)
                diffColors[color] = (diffColors[color] ?? 0) + diffRed + diffGreen + diffBlue
            }
        }
        return top(diffColors, number: number)
    }

}
