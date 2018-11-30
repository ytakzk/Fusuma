//
//  UIColorExtensions.swift
//  Fusuma
//
//  Created by Nick Kezhaya on 11/30/18.
//  Copyright © 2018 ytakzk. All rights reserved.
//

import UIKit

internal extension UIColor {
    class func hex(_ hexStr: NSString, alpha: CGFloat) -> UIColor {
        let realHexStr = hexStr.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: realHexStr as String)
        var color: UInt32 = 0

        if scanner.scanHexInt32(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        } else {
            return UIColor.white
        }
    }
}
