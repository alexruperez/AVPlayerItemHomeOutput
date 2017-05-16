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
    var hasPrimaryHome: Bool {
        return primaryHome != nil
    }
    private var lightbulbServices: [HMService]? {
        return primaryHome?.servicesWithTypes([HMServiceTypeLightbulb])
    }
    var updating = [HMCharacteristic: Bool]()

    func send(_ pixelBuffer: CVPixelBuffer, colors: UInt) {
        guard hasPrimaryHome && colors > 0 else {
            return
        }
        var samples = [[UInt8]]()
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = image.extent
        for i in 0..<colors {
            for j in 0..<colors {
                let inputExtent = CIVector(x: (extent.size.width / CGFloat(colors)) * CGFloat(i), y: (extent.size.height / CGFloat(colors)) * CGFloat(j), z: extent.size.width / CGFloat(colors), w: extent.size.height / CGFloat(colors))
                guard let outputImage = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: image, kCIInputExtentKey: inputExtent])?.outputImage else {
                    break
                }
                var bitmap = [UInt8](repeating: 0, count: 4)
                CIContext().render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
                samples.append(bitmap)
            }
        }
        send(diff(samples, number: Int(colors)))
    }

    func send(_ colors: [UIColor]) {
        guard let lightbulbServices = lightbulbServices, colors.count > 0 else {
            return
        }
        var colorIndex = 0
        for lightbulbService in lightbulbServices {
            var HSBA = [CGFloat](repeating: 0, count: 4)
            colors[colorIndex % colors.count].getHue(&HSBA[0], saturation: &HSBA[1], brightness: &HSBA[2], alpha: &HSBA[3])
            for characteristic in lightbulbService.characteristics {
                guard updating[characteristic] == nil || updating[characteristic] == false else {
                    break
                }
                switch characteristic.characteristicType {
                case HMCharacteristicTypePowerState:
                    update(characteristic, floatValue: 1)
                case HMCharacteristicTypeBrightness:
                    update(characteristic, floatValue: Float(HSBA[2]))
                case HMCharacteristicTypeSaturation:
                    update(characteristic, floatValue: Float(HSBA[1]))
                case HMCharacteristicTypeHue:
                    update(characteristic, floatValue: Float(HSBA[0]))
                default:
                    break
                }
            }
            colorIndex += 1
        }
    }

}

extension HomeManager {

    func update(_ characteristic: HMCharacteristic, floatValue: Float) {
        let value = NSNumber(value: Int(floatValue * (characteristic.metadata?.maximumValue?.floatValue ?? (floatValue > 1 ? 100 : 1))))
        guard characteristic.value as? Float != value.floatValue else {
            return
        }
        updating[characteristic] = true
        characteristic.writeValue(value, completionHandler: { error in
            self.unlock(characteristic, error)
        })
    }

    func unlock(_ characteristic: HMCharacteristic, _ error: Error?) {
        if error != nil {
            let deadline: DispatchTime = .now() + .seconds(1)
            DispatchQueue.global().asyncAfter(deadline: deadline, execute: { [weak self] in
                self?.updating[characteristic] = false
            })
        } else {
            self.updating[characteristic] = false
        }
    }

    func top(_ colors: [UIColor: CGFloat], number: Int) -> [UIColor] {
        return colors.sorted(by: { $0.1 > $1.1 }).prefix(number).map({ $0.0 })
    }

    func diff(_ colors: [[UInt8]], number: Int) -> [UIColor] {
        var diffColors = [UIColor: CGFloat]()
        for components in colors {
            for diffComponents in colors {
                guard components != diffComponents || number == 1 else {
                    break
                }
                let diffRed = abs(CGFloat(components[0]) - CGFloat(diffComponents[0]))
                let diffGreen = abs(CGFloat(components[1]) - CGFloat(diffComponents[1]))
                let diffBlue = abs(CGFloat(components[2]) - CGFloat(diffComponents[2]))
                let color = UIColor(red: CGFloat(components[0]) / 255, green: CGFloat(components[1]) / 255, blue: CGFloat(components[2]) / 255, alpha: CGFloat(components[3]) / 255)
                diffColors[color] = (diffColors[color] ?? 0) + diffRed + diffGreen + diffBlue
            }
        }
        return top(diffColors, number: number)
    }

}
