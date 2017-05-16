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
                var bitmap = [UInt8](repeating: 0, count: 4)
                let context = CIContext()
                let x = (extent.size.width / CGFloat(colors)) * CGFloat(i)
                let y = (extent.size.height / CGFloat(colors)) * CGFloat(j)
                let width = extent.size.width / CGFloat(colors)
                let height = extent.size.height / CGFloat(colors)
                let inputExtent = CIVector(x: x, y: y, z: width, w: height)
                let inputParameters = [kCIInputImageKey: image, kCIInputExtentKey: inputExtent]
                guard let filter = CIFilter(name: "CIAreaAverage", withInputParameters: inputParameters), let outputImage = filter.outputImage else {
                    break
                }
                let outputExtent = outputImage.extent
                assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
                let bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
                context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: bounds, format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
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
            let color = colors[colorIndex % colors.count]
            var HSBA = [CGFloat](repeating: 0, count: 4)
            color.getHue(&HSBA[0], saturation: &HSBA[1], brightness: &HSBA[2], alpha: &HSBA[3])
            for characteristic in lightbulbService.characteristics {
                if updating[characteristic] == nil {
                    updating[characteristic] = false
                }
                guard updating[characteristic] == false else {
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
        if characteristic.value as? Float != value.floatValue {
            updating[characteristic] = true
            characteristic.writeValue(value, completionHandler: { error in
                if error != nil {
                    let deadline: DispatchTime = .now() + .seconds(1)
                    DispatchQueue.global().asyncAfter(deadline: deadline, execute: { [weak self] in
                        self?.updating[characteristic] = false
                    })
                } else {
                    self.updating[characteristic] = false
                }
            })
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
                let red = CGFloat(components[0]) / 255
                let green = CGFloat(components[1]) / 255
                let blue = CGFloat(components[2]) / 255
                let alpha = CGFloat(components[3]) / 255
                let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
                diffColors[color] = (diffColors[color] ?? 0) + diffRed + diffGreen + diffBlue
            }
        }
        return top(diffColors, number: number)
    }

}
