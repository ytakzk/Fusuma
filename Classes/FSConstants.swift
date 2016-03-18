//
//  FSConstants.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/08/31.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

// Extension
internal extension UIColor {
    
    class func hex (hexStr : NSString, alpha : CGFloat) -> UIColor {
        
        let realHexStr = hexStr.stringByReplacingOccurrencesOfString("#", withString: "")
        let scanner = NSScanner(string: realHexStr as String)
        var color: UInt32 = 0
        if scanner.scanHexInt(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red:r,green:g,blue:b,alpha:alpha)
        } else {
            print("invalid hex string", terminator: "")
            return UIColor.whiteColor()
        }
    }
}

extension UIView {
    
    func addBottomBorder(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.borderColor = color.CGColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: width)
        border.borderWidth = width
        self.layer.addSublayer(border)
    }

}