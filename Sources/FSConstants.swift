//
//  FSConstants.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/08/31.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

internal struct FSDefaults {
    static var baseTintColor = UIColor.hex("#FFFFFF", alpha: 1.0)
    static var tintColor = UIColor.hex("#009688", alpha: 1.0)
    static var backgroundColor = UIColor.hex("#212121", alpha: 1.0)

    static var cropImage = true
    static var tintIcons = true

    static var cameraRollTitle = "CAMERA ROLL"
    static var cameraTitle = "PHOTO"
    static var videoTitle = "VIDEO"
}

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

public extension UIView {
    public class func fromNib(nibNameOrNil: String? = nil) -> Self {
        return fromNib(nibNameOrNil, type: self)
    }

    public class func fromNib<T : UIView>(nibNameOrNil: String? = nil, type: T.Type) -> T {
        let v: T? = fromNib(nibNameOrNil, type: T.self)
        return v!
    }

    public class func fromNib<T : UIView>(nibNameOrNil: String? = nil, type: T.Type) -> T? {
        var view: T?
        let name = nibNameOrNil ?? nibName
        let nibViews = NSBundle(forClass: self).loadNibNamed(name, owner: self, options: nil)
        for v in nibViews {
            if let tog = v as? T {
                view = tog
            }
        }
        return view
    }

    public class var nibName: String {
        let name = "\(self)".componentsSeparatedByString(".").first ?? ""
        return name
    }
    public class var nib: UINib? {
        if let _ = NSBundle(forClass: self).pathForResource(nibName, ofType: "nib") {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }
}